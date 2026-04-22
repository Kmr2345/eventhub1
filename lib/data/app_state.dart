import 'package:flutter/material.dart';
import 'package:eventhub/models/event_model.dart';
import 'package:eventhub/data/mock_data.dart';

class AppState extends ChangeNotifier {
  UserModel? user;
  String? token;
  String language = 'ru';
  List<EventModel> events = getMockEvents();
  final Map<String, List<String>> registrations = {};
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
    notifyListeners();
  }

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  // Favorites
  void toggleFavorite(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      events[idx].isFavorite = !events[idx].isFavorite;
      notifyListeners();
    }
  }

  // Registration
  bool isRegistered(String eventId) =>
      registrations[eventId]?.contains(user?.email) ?? false;

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

  List<EventModel> get favorites => events.where((e) => e.isFavorite).toList();
  List<EventModel> get myEvents  => events.where((e) => e.organizerId == 'org1').toList();
}
