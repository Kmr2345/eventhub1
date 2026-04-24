import 'package:flutter/material.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/services/api_service.dart';

class AppState extends ChangeNotifier {
  UserModel? user;
  String? token;
  String language = 'ru';
  List<EventModel> events = [];
  final Map<String, List<String>> registrations = {};
  List<dynamic> myRegistrations = [];
  List<dynamic> favorites = [];
  List<dynamic> notifications = [];
  final Map<String, int> userRatings = {};

  // Auth
  void login(String email, String name, String role) {
    user = UserModel(name: name, email: email, role: role);
    notifyListeners();
  }

  void setToken(String t) {
    token = t;
    notifyListeners();
  }

  void setEvents(List<EventModel> newEvents) {
    events = newEvents;
    notifyListeners();
  }

  void logout() {
    user = null;
    token = null;
    myRegistrations = [];
    favorites = [];
    notifications = [];
    events = [];
    notifyListeners();
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  // Favorites (synced with backend via ApiService.getFavorites)
  void setFavorites(List<dynamic> favs) {
    favorites = favs;

    final favIds = <String>{};
    for (final f in favs) {
      if (f is! Map) continue;
      final ev = f['eventId'];
      final evId = ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
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
      final evId = ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
      if (evId == eventId) return true;
    }
    return false;
  }

  List<EventModel> get favoriteEvents => events.where((e) => isFavoriteEvent(e.id)).toList();

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

  // Registration
  bool isRegistered(String eventId) {
    // Prefer backend truth if loaded.
    if (myRegistrations.isNotEmpty) {
      for (final r in myRegistrations) {
        if (r is! Map) continue;
        final status = r['status']?.toString();
        if (status == 'cancelled') continue;
        final ev = r['eventId'];
        final evId = ev is Map ? (ev['_id'] ?? ev['id'])?.toString() : ev?.toString();
        if (evId == eventId) return true;
      }
      return false;
    }
    // Fallback to local-only state (legacy).
    return registrations[eventId]?.contains(user?.email) ?? false;
  }

  Future<void> refreshMyRegistrations() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    final data = await ApiService.getMyRegistrations(t);
    myRegistrations = data;
    notifyListeners();
  }

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

  Future<void> markAllNotificationsRead() async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.readAllNotifications(t);
    await refreshNotifications();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final t = token;
    if (t == null || t.isEmpty) return;
    await ApiService.markNotificationRead(notificationId, t);
    await refreshNotifications();
  }

  void markNotificationAsRead(String id) {
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

  // Backwards compatibility (older call site name)
  void markNotificationAsReadLocal(String id) => markNotificationAsRead(id);

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

  void toggleRegistration(String eventId) {
    final email = user?.email ?? '';
    final regs = registrations[eventId] ?? [];
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;

    if (regs.contains(email)) {
      regs.remove(email);
      events[idx].registered = (events[idx].registered - 1).clamp(0, 9999);
    } else {
      if (events[idx].spotsLeft <= 0) return;
      regs.add(email);
      events[idx].registered += 1;
    }
    registrations[eventId] = regs;
    notifyListeners();
  }

  List<String> getParticipants(String eventId) => registrations[eventId] ?? [];

  // Rating
  void rateEvent(String eventId, int rating) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;
    final e = events[idx];
    final oldTotal = e.rating * e.totalRatings;
    e.totalRatings += 1;
    e.rating = (oldTotal + rating) / e.totalRatings;
    userRatings[eventId] = rating;
    notifyListeners();
  }

  int? getUserRating(String eventId) => userRatings[eventId];

  // Create / Edit / Delete event
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

  // Filtered events
  List<EventModel> filtered({String query = '', String category = 'All'}) {
    return events.where((e) {
      final title = e.getTitle(language).toLowerCase();
      final matchQ = query.isEmpty || title.contains(query.toLowerCase());
      final matchC = category == 'All' || e.category == category;
      return matchQ && matchC;
    }).toList();
  }

  // keep old name for screens that show favorites list
  List<EventModel> get favoritesEvents => favoriteEvents;
  List<EventModel> get myEvents  {
    final u = user;
    if (u == null) return const [];
    // Backend may store organizer by id or name; best-effort filter.
    return events.where((e) => e.organizerName == u.name || e.organizerId == u.email).toList();
  }
}
