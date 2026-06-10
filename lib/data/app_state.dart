import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? user;
  String? token;
  String language = 'ru';
  bool isDarkMode = false;

  List<EventModel> events = [];
  List<dynamic> myRegistrations = [];
  List<dynamic> favorites = [];
  List<dynamic> notifications = [];
  bool isLoading = true;

  AppState() {
    _restoreSession();
  }

  // ─── SESSION ──────────────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');
      final savedEmail = prefs.getString('user_email');
      final savedName = prefs.getString('user_name');
      final savedRole = prefs.getString('user_role');
      final savedLang = prefs.getString('language');

      if (savedLang != null) language = savedLang;
      final savedDark = prefs.getBool('dark_mode');
      if (savedDark != null) isDarkMode = savedDark;

      if (savedToken != null &&
          savedEmail != null &&
          savedName != null &&
          savedRole != null) {
        token = savedToken;
        final savedUserId = prefs.getString('user_id') ?? '';
        user = UserModel(
            id: savedUserId,
            name: savedName,
            email: savedEmail,
            role: savedRole);

        try {
          await refreshMyRegistrations();
          final eventsData = await ApiService.getEvents(savedToken);
          events = eventsData
              .whereType<Map<String, dynamic>>()
              .map(EventModel.fromJson)
              .toList();

          final favs = await ApiService.getFavorites(savedToken);
          setFavorites(favs);
          await refreshNotifications();
        } catch (_) {
          await _clearSession();
        }
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (user != null) {
      await prefs.setString('user_id', user!.id);
      await prefs.setString('user_email', user!.email);
      await prefs.setString('user_name', user!.name);
      await prefs.setString('user_role', user!.role);
    }
    await prefs.setString('language', language);
    await prefs.setBool('dark_mode', isDarkMode);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    // dark_mode и language намеренно НЕ удаляем — сохраняем после logout
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  void login(String email, String name, String role, {String userId = ''}) {
    user = UserModel(id: userId, name: name, email: email, role: role);
    _saveSession();
    notifyListeners();
  }

  void setToken(String t) {
    token = t;
    notifyListeners();
  }

  void logout() {
    user = null;
    token = null;
    myRegistrations = [];
    favorites = [];
    notifications = [];
    events = [];
    _clearSession();
    notifyListeners();
  }

  void setLanguage(String lang) {
    language = lang;
    _saveSession();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    isDarkMode = value;
    _saveSession();
    notifyListeners();
  }

  // ─── EVENTS ───────────────────────────────────────────────────────────────

  void setEvents(List<EventModel> newEvents) {
    events = newEvents;
    notifyListeners();
  }

  void addEvent(EventModel event) {
    events.insert(0, event);
    notifyListeners();
  }

  void updateEvent(EventModel updated) {
    final idx = events.indexWhere((e) => e.id == updated.id);
    if (idx != -1) events[idx] = updated;
    notifyListeners();
  }

  void deleteEvent(String eventId) {
    events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }

  void updateEventRating(String eventId, double avgRating, int totalRatings) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    events[idx].rating = avgRating;
    events[idx].totalRatings = totalRatings;
    notifyListeners();
  }

  List<EventModel> filtered({String query = '', String category = 'All'}) {
    return events.where((e) {
      final title = e.getTitle(language).toLowerCase();
      final matchQ = query.isEmpty || title.contains(query.toLowerCase());
      final matchC = category == 'All' || e.category == category;
      return matchQ && matchC;
    }).toList();
  }

  List<EventModel> get myEvents {
    final u = user;
    if (u == null) return const [];
    return events.where((e) => e.organizerId == u.id).toList();
  }

  // ─── FAVORITES ────────────────────────────────────────────────────────────

  void setFavorites(List<dynamic> favs) {
    favorites = favs;

    final favIds = <String>{};
    for (final f in favs) {
      if (f is! Map) continue;
      final ev = f['eventId'];
      final evId =
      ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
      if (evId != null && evId.isNotEmpty) favIds.add(evId);
    }

    for (final e in events) {
      e.isFavorite = favIds.contains(e.id);
    }

    notifyListeners();
  }

  bool isFavoriteEvent(String eventId) {
    for (final f in favorites) {
      if (f is! Map) continue;
      final ev = f['eventId'];
      final evId =
      ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
      if (evId == eventId) return true;
    }
    return false;
  }

  List<EventModel> get favoriteEvents =>
      events.where((e) => isFavoriteEvent(e.id)).toList();

  List<EventModel> get favoritesEvents => favoriteEvents;

  Future<void> syncToggleFavorite(String eventId) async {
    final t = token;
    if (t == null || t.isEmpty) return;

    if (isFavoriteEvent(eventId)) {
      await ApiService.removeFavorite(eventId, t);
    } else {
      await ApiService.addFavorite(eventId, t);
    }

    final favs = await ApiService.getFavorites(t);
    setFavorites(favs);
  }

  // ─── REGISTRATIONS ────────────────────────────────────────────────────────

  bool isRegistered(String eventId) {
    for (final r in myRegistrations) {
      if (r is! Map) continue;
      final status = r['status']?.toString();
      if (status == 'cancelled') continue;
      final ev = r['eventId'];
      final evId =
      ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
      if (evId == eventId) return true;
    }
    return false;
  }

  Future<void> refreshMyRegistrations() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    final data = await ApiService.getMyRegistrations(t);
    myRegistrations = data;
    notifyListeners();
  }

  String? findRegistrationIdForEvent(String eventId) {
    for (final r in myRegistrations) {
      if (r is! Map) continue;
      final regId = (r['_id'] ?? r['id'])?.toString();
      final ev = r['eventId'];
      String? evId;
      if (ev is Map) {
        evId = (ev['_id'] ?? ev['id'])?.toString();
      } else {
        evId = ev?.toString();
      }
      if (evId != null && evId == eventId) return regId;
    }
    return null;
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<void> refreshNotifications() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    final data = await ApiService.getNotifications(t);
    notifications = data;
    notifyListeners();
  }

  void setNotifications(List<dynamic> list) {
    notifications = list;
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.markNotificationRead(notificationId, t);
    _applyNotificationReadLocally(notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.readAllNotifications(t);
    await refreshNotifications();
  }

  Future<void> deleteNotification(String id) async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.deleteNotification(id, t);
    notifications = notifications.where((n) {
      if (n is! Map) return false;
      return (n['_id'] ?? n['id'])?.toString() != id;
    }).toList();
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.clearAllNotifications(t);
    notifications = [];
    notifyListeners();
  }

  void _applyNotificationReadLocally(String id) {
    notifications = notifications.map((n) {
      if (n is! Map) return n;
      final nid = (n['_id'] ?? n['id'])?.toString();
      if (nid != id) return n;
      final next = Map<String, dynamic>.from(n.cast());
      next['read'] = true;
      next['isRead'] = true;
      return next;
    }).toList();
    notifyListeners();
  }

  void markNotificationAsRead(String id) => _applyNotificationReadLocally(id);

  // Используется в profile_screen.dart
  final Map<String, int> userRatings = {};
  int? getUserRating(String eventId) => userRatings[eventId];

  List<String> getParticipants(String eventId) => const [];
}