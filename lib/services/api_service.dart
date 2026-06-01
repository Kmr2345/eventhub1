import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // ─── КОНФИГУРАЦИЯ ─────────────────────────────────────────────────────────
  // Замените значения ниже перед запуском на телефоне и перед защитой:
  //
  //   _localIp      — IP вашего ноутбука в локальной Wi-Fi сети.
  //                   Узнать: команда  ipconfig  (Windows) → IPv4 Address
  //                   Пример: '192.168.1.15'
  //
  //   _productionUrl — адрес сервера в интернете (если есть деплой).
  //                    Если нет — оставьте совпадающим с _localIp.
  // ─────────────────────────────────────────────────────────────────────────
  static const String _localIp = '192.168.1.15';
  static const String _localPort = '5000';
  static const String _productionUrl = 'http://$_localIp:$_localPort'; // ← или https://your-domain.com

  // URL для API-запросов приложения
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_localPort';
    return 'http://$_localIp:$_localPort';
  }

  // URL для share-ссылок (WhatsApp, Telegram, буфер обмена).
  // Всегда использует реальный IP — чтобы ссылка открывалась у получателя.
  static String get shareBaseUrl => 'http://$_localIp:$_localPort';

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> _jsonAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static void _logRequest({
    required String method,
    required String url,
    String? token,
    Object? body,
  }) {
    assert(() {
      print('[$method] $url');
      if (body != null) print('BODY: $body');
      return true;
    }());
  }

  static dynamic _decodeAny(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw Exception('Invalid JSON response (${res.statusCode}): ${res.body}');
    }
  }

  static Exception _httpError(http.Response res, {Map<String, dynamic>? decoded}) {
    final d = decoded;
    final msg = d?['message']?.toString() ??
        d?['error']?.toString() ??
        'Request failed (${res.statusCode})';
    return Exception(msg);
  }

  // Успешный статус: 200 или 201 (Created)
  static bool _isSuccess(int code) => code == 200 || code == 201;

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  static Future<List> getNotifications(String token) async {
    final url = '$baseUrl/notifications';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> readAllNotifications(String token) async {
    final url = '$baseUrl/notifications/readAll';
    _logRequest(method: 'POST', url: url);
    final res = await http.post(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  static Future<Map<String, dynamic>> markNotificationRead(
      String notificationId, String token) async {
    final url = '$baseUrl/notifications/read/$notificationId';
    _logRequest(method: 'PUT', url: url);
    final res = await http.put(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  // ─── FAVORITES ────────────────────────────────────────────────────────────

  static Future<List> getFavorites(String token) async {
    final url = '$baseUrl/favorites';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> addFavorite(String eventId, String token) async {
    final url = '$baseUrl/favorites';
    final body = jsonEncode({'eventId': eventId});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> removeFavorite(String eventId, String token) async {
    final url = '$baseUrl/favorites/$eventId';
    _logRequest(method: 'DELETE', url: url);
    final res = await http.delete(Uri.parse(url), headers: _jsonAuthHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  // ─── EVENTS ───────────────────────────────────────────────────────────────

  static Future<List> getEvents(String token) async {
    final url = '$baseUrl/events';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> createEvent(
      Map<String, dynamic> data, String token) async {
    final url = '$baseUrl/events';
    final body = jsonEncode(data);
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    // POST может вернуть 201 Created
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> updateEvent(
      String eventId, Map<String, dynamic> data, String token) async {
    final url = '$baseUrl/events/$eventId';
    final body = jsonEncode(data);
    _logRequest(method: 'PUT', url: url, body: body);
    final res = await http.put(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> getEventById(String eventId) async {
    final url = '$baseUrl/events/$eventId';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<void> deleteEvent(String eventId, String token) async {
    final url = '$baseUrl/events/$eventId';
    _logRequest(method: 'DELETE', url: url);
    final res = await http.delete(Uri.parse(url), headers: _authHeaders(token));
    if (!_isSuccess(res.statusCode)) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
  }

  // ─── REGISTRATIONS ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> registerToEvent(
      String eventId, String token) async {
    final url = '$baseUrl/registrations';
    final body = jsonEncode({'eventId': eventId});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    // POST /registrations вернёт 201
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<List> getMyRegistrations(String token) async {
    final url = '$baseUrl/registrations/my';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> cancelRegistration(
      String registrationId, String token) async {
    final url = '$baseUrl/registrations/$registrationId/cancel';
    _logRequest(method: 'PUT', url: url);
    final res = await http.put(Uri.parse(url), headers: _jsonAuthHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw Exception('Cancel failed');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<List> getEventRegistrations(String eventId, String token) async {
    final url = '$baseUrl/registrations/event/$eventId';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) throw _httpError(res);
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<List<dynamic>> getEventParticipants(String eventId, String token) {
    return getEventRegistrations(eventId, token);
  }

  static Future<dynamic> markAttended(String registrationId, String token) async {
    final url = '$baseUrl/registrations/$registrationId/attended';
    _logRequest(method: 'PUT', url: url);
    final res = await http.put(Uri.parse(url), headers: _jsonAuthHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    return decoded;
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
    final url = '$baseUrl/auth/register';
    final body = jsonEncode({'name': name, 'email': email, 'password': password, 'role': role});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);
    final data = _decodeAny(res);
    // 201 Created — нормальный ответ для регистрации
    if (!_isSuccess(res.statusCode)) {
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      if (data is String) throw Exception(data);
      throw Exception(data.toString());
    }
    if (data is! Map) throw Exception('Unexpected register response: ${data.runtimeType}');
    return data.cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '$baseUrl/auth/login';
    final body = jsonEncode({'email': email, 'password': password});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);
    final data = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      if (data is String) throw Exception(data);
      throw Exception(data.toString());
    }
    if (data is! Map) throw Exception('Unexpected login response: ${data.runtimeType}');
    final decoded = data.cast<String, dynamic>();
    if (decoded['token'] == null || decoded['user'] == null) {
      throw Exception('Unexpected login response: missing token/user');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final url = '$baseUrl/auth/verify';
    final body = jsonEncode({'email': email, 'code': code});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);
    final data = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      throw Exception(data.toString());
    }
    if (data is! Map) throw Exception('Unexpected response');
    return data.cast<String, dynamic>();
  }

  static Future<void> resendCode(String email) async {
    final url = '$baseUrl/auth/resend-code';
    final body = jsonEncode({'email': email});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);
    if (!_isSuccess(res.statusCode)) {
      final data = _decodeAny(res);
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      throw Exception('Failed to resend code');
    }
  }

  // ─── REVIEWS ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getReviews(String eventId) async {
    final url = '$baseUrl/reviews/event/$eventId';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> submitReview(
      String eventId, int rating, String comment, String token) async {
    final url = '$baseUrl/reviews';
    final body = jsonEncode({'eventId': eventId, 'rating': rating, 'comment': comment});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    // 201 Created — нормальный ответ
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> canReview(String eventId, String token) async {
    final url = '$baseUrl/reviews/can-review/$eventId';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> editReview(
      String reviewId, int rating, String comment, String token) async {
    final url = '$baseUrl/reviews/$reviewId';
    final body = jsonEncode({'rating': rating, 'comment': comment});
    _logRequest(method: 'PATCH', url: url, body: body);
    final res = await http.patch(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<void> deleteReview(String reviewId, String token) async {
    final url = '$baseUrl/reviews/$reviewId';
    _logRequest(method: 'DELETE', url: url);
    final res = await http.delete(Uri.parse(url), headers: _authHeaders(token));
    if (!_isSuccess(res.statusCode)) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  static Future<List> adminGetUsers(String token) async {
    final url = '$baseUrl/admin/users';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> adminChangeRole(
      String userId, String role, String token) async {
    final url = '$baseUrl/admin/users/$userId/role';
    final body = jsonEncode({'role': role});
    _logRequest(method: 'PATCH', url: url, body: body);
    final res = await http.patch(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<void> adminDeleteUser(String userId, String token) async {
    final url = '$baseUrl/admin/users/$userId';
    _logRequest(method: 'DELETE', url: url);
    final res = await http.delete(Uri.parse(url), headers: _authHeaders(token));
    if (!_isSuccess(res.statusCode)) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
  }

  static Future<void> adminDeleteEvent(String eventId, String token) async {
    final url = '$baseUrl/admin/events/$eventId';
    _logRequest(method: 'DELETE', url: url);
    final res = await http.delete(Uri.parse(url), headers: _authHeaders(token));
    if (!_isSuccess(res.statusCode)) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
  }

  static Future<Map<String, dynamic>> adminGetStats(String token) async {
    final url = '$baseUrl/admin/stats';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url), headers: _authHeaders(token));
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final url = '$baseUrl/profile';
    final body = jsonEncode({
      if (name != null) 'name': name,
      if (currentPassword != null) 'currentPassword': currentPassword,
      if (newPassword != null) 'newPassword': newPassword,
    });
    _logRequest(method: 'PATCH', url: url, body: body);
    final res = await http.patch(Uri.parse(url), headers: _jsonAuthHeaders(token), body: body);
    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  // ─── IMAGE UPLOAD ─────────────────────────────────────────────────────────

  static Future<String> uploadImage(dynamic imageFile, String token) async {
    final url = '$baseUrl/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    final decoded = _decodeAny(res);
    if (!_isSuccess(res.statusCode)) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic> && decoded['url'] != null) {
      return decoded['url'] as String;
    }
    throw Exception('Upload failed: no URL in response');
  }
}