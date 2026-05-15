import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _productionUrl = 'http://YOUR_SERVER_IP:5000';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return const bool.fromEnvironment('dart.vm.product')
        ? _productionUrl
        : 'http://10.0.2.2:5000';
  }

  static void _logRequest({
    required String method,
    required String url,
    String? token,
    Object? body,
  }) {
    assert(() {
      print('REQUEST URL: $url');
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

  // NOTIFICATIONS
  static Future<List> getNotifications(String token) async {
    final url = '$baseUrl/notifications';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> readAllNotifications(String token) async {
    final url = '$baseUrl/notifications/readAll';
    _logRequest(method: 'POST', url: url, token: token);
    final res = await http.post(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  static Future<Map<String, dynamic>> markNotificationRead(String notificationId, String token) async {
    final url = '$baseUrl/notifications/read/$notificationId';
    _logRequest(method: 'PUT', url: url, token: token);
    final res = await http.put(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  // FAVORITES
  static Future<List> getFavorites(String token) async {
    final url = '$baseUrl/favorites';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> addFavorite(String eventId, String token) async {
    final url = '$baseUrl/favorites';
    final body = jsonEncode({'eventId': eventId});
    _logRequest(method: 'POST', url: url, token: token, body: body);
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> removeFavorite(String eventId, String token) async {
    final url = '$baseUrl/favorites/$eventId';
    _logRequest(method: 'DELETE', url: url, token: token);
    final res = await http.delete(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'message': decoded.toString()};
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data, String token) async {
    final url = '$baseUrl/events';
    final body = jsonEncode(data);
    _logRequest(method: 'POST', url: url, token: token, body: body);
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> updateEvent(String eventId, Map<String, dynamic> data, String token) async {
    final url = '$baseUrl/events/$eventId';
    final body = jsonEncode(data);
    _logRequest(method: 'PUT', url: url, token: token, body: body);
    final res = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
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
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> registerToEvent(String eventId, String token) async {
    final url = '$baseUrl/registrations';
    final body = jsonEncode({'eventId': eventId});
    _logRequest(method: 'POST', url: url, token: token, body: body);
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<List> getMyRegistrations(String token) async {
    final url = '$baseUrl/registrations/my';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> cancelRegistration(String registrationId, String token) async {
    final url = '$baseUrl/registrations/$registrationId/cancel';
    _logRequest(method: 'PUT', url: url, token: token);
    final res = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token});
    print('CANCEL RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw Exception('Cancel failed');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final url = '$baseUrl/auth/verify';
    final body = jsonEncode({'email': email, 'code': code});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);
    print('RESPONSE: ${res.body}');
    final data = _decodeAny(res);
    if (res.statusCode != 200) {
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
    print('RESPONSE: ${res.body}');
    if (res.statusCode != 200) {
      final data = _decodeAny(res);
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      throw Exception('Failed to resend code');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final url = '$baseUrl/auth/register';
    final body = jsonEncode({'name': name, 'email': email, 'password': password, 'role': role});
    _logRequest(method: 'POST', url: url, body: body);
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);
    print('RESPONSE: ${res.body}');
    final data = _decodeAny(res);
    if (res.statusCode != 200) {
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
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: body);
    print('RESPONSE: ${res.body}');
    final data = _decodeAny(res);
    if (res.statusCode != 200) {
      if (data is Map) throw Exception(data['message']?.toString() ?? data.toString());
      if (data is String) throw Exception(data);
      throw Exception(data.toString());
    }
    if (data is! Map) throw Exception('Unexpected login response: ${data.runtimeType}');
    final decoded = data.cast<String, dynamic>();
    if (decoded['token'] == null || decoded['user'] == null) throw Exception('Unexpected login response: missing token/user');
    return decoded;
  }

  static Future<List> getEvents(String token) async {
    final url = '$baseUrl/events';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<List> getEventRegistrations(String eventId, String token) async {
    final url = '$baseUrl/registrations/event/$eventId';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) throw _httpError(res);
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format');
  }

  // Alias used by admin screen
  static Future<List<dynamic>> getEventParticipants(String eventId, String token) {
    return getEventRegistrations(eventId, token);
  }

  static Future<dynamic> markAttended(String registrationId, String token) async {
    final url = '$baseUrl/registrations/$registrationId/attended';
    _logRequest(method: 'PUT', url: url, token: token);
    final res = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token});
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    return decoded;
  }

  // REVIEWS
  static Future<Map<String, dynamic>> getReviews(String eventId) async {
    final url = '$baseUrl/reviews/event/$eventId';
    _logRequest(method: 'GET', url: url);
    final res = await http.get(Uri.parse(url));
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> submitReview(String eventId, int rating, String comment, String token) async {
    final url = '$baseUrl/reviews';
    final body = jsonEncode({'eventId': eventId, 'rating': rating, 'comment': comment});
    _logRequest(method: 'POST', url: url, token: token, body: body);
    final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> canReview(String eventId, String token) async {
    final url = '$baseUrl/reviews/can-review/$eventId';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  // ADMIN
  static Future<List> adminGetUsers(String token) async {
    final url = '$baseUrl/admin/users';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> adminChangeRole(String userId, String role, String token) async {
    final url = '$baseUrl/admin/users/$userId/role';
    final body = jsonEncode({'role': role});
    _logRequest(method: 'PATCH', url: url, token: token, body: body);
    final res = await http.patch(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': token}, body: body);
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<void> adminDeleteUser(String userId, String token) async {
    final url = '$baseUrl/admin/users/$userId';
    _logRequest(method: 'DELETE', url: url, token: token);
    final res = await http.delete(Uri.parse(url), headers: {'Authorization': token});
    if (res.statusCode != 200) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
  }

  static Future<void> adminDeleteEvent(String eventId, String token) async {
    final url = '$baseUrl/admin/events/$eventId';
    _logRequest(method: 'DELETE', url: url, token: token);
    final res = await http.delete(Uri.parse(url), headers: {'Authorization': token});
    if (res.statusCode != 200) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
  }

  static Future<Map<String, dynamic>> adminGetStats(String token) async {
    final url = '$baseUrl/admin/stats';
    _logRequest(method: 'GET', url: url, token: token);
    final res = await http.get(Uri.parse(url), headers: {'Authorization': token});
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  // PROFILE
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
    _logRequest(method: 'PATCH', url: url, token: token, body: body);
    final res = await http.patch(Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  // REVIEW EDIT / DELETE
  static Future<Map<String, dynamic>> editReview(
      String reviewId, int rating, String comment, String token) async {
    final url = '$baseUrl/reviews/$reviewId';
    final body = jsonEncode({'rating': rating, 'comment': comment});
    _logRequest(method: 'PATCH', url: url, token: token, body: body);
    final res = await http.patch(Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: body);
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format');
  }

  static Future<void> deleteReview(String reviewId, String token) async {
    final url = '$baseUrl/reviews/$reviewId';
    _logRequest(method: 'DELETE', url: url, token: token);
    final res = await http.delete(Uri.parse(url),
        headers: {'Authorization': token});
    print('RESPONSE: ${res.body}');
    if (res.statusCode != 200) {
      final decoded = _decodeAny(res);
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      if (decoded is String) throw Exception(decoded);
      throw _httpError(res);
    }
  }

  // IMAGE UPLOAD
  static Future<String> uploadImage(dynamic imageFile, String token) async {
    final url = '$baseUrl/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = token;

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'upload.jpg',
      );
      request.files.add(multipartFile);
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);
    print('UPLOAD RESPONSE: ${res.body}');

    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic> && decoded['url'] != null) {
      return decoded['url'] as String;
    }
    throw Exception('Upload failed: no URL in response');
  }
}