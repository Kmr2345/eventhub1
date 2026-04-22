import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  static void _logRequest({
    required String method,
    required String url,
    String? token,
    Object? body,
  }) {
    print('REQUEST URL: $url');
    if (body != null) print('BODY: $body');
    if (token != null) print('TOKEN: $token');
  }

  static Map<String, dynamic> _decodeMap(http.Response res) {
    try {
      return (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw Exception('Invalid JSON response (${res.statusCode}): ${res.body}');
    }
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

  static Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> data,
    String token,
  ) async {
    final url = '$baseUrl/events';
    final body = jsonEncode(data);
    _logRequest(method: 'POST', url: url, token: token, body: body);

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: body,
    );

    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> registerToEvent(
    String eventId,
    String token,
  ) async {
    final url = '$baseUrl/registrations';
    final body = jsonEncode({'eventId': eventId});
    _logRequest(method: 'POST', url: url, token: token, body: body);

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: body,
    );

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

    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': token},
    );

    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> cancelRegistration(
    String registrationId,
    String token,
  ) async {
    final url = '$baseUrl/registrations/$registrationId/cancel';
    _logRequest(method: 'PUT', url: url, token: token);

    final res = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    print('CANCEL RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw Exception('Cancel failed');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = '$baseUrl/auth/register';
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    _logRequest(method: 'POST', url: url, body: body);

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('RESPONSE: ${res.body}');
    final decoded = _decodeMap(res);
    if (res.statusCode != 200) throw _httpError(res, decoded: decoded);
    return decoded;
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '$baseUrl/auth/login';
    final body = jsonEncode({'email': email, 'password': password});
    _logRequest(method: 'POST', url: url, body: body);

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('RESPONSE: ${res.body}');
    final decoded = _decodeMap(res);
    if (res.statusCode != 200) throw _httpError(res, decoded: decoded);
    if (decoded['token'] == null || decoded['user'] == null) {
      throw Exception('Unexpected login response: missing token/user');
    }
    return decoded;
  }

  // GET EVENTS
  static Future<List> getEvents(String token) async {
    final url = '$baseUrl/events';
    _logRequest(method: 'GET', url: url, token: token);

    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': token},
    );
    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected response format: ${decoded.runtimeType}');
  }

  static Future<dynamic> markAttended(String registrationId, String token) async {
    final url = '$baseUrl/registrations/$registrationId/attended';
    _logRequest(method: 'PUT', url: url, token: token);

    final res = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    print('RESPONSE: ${res.body}');
    final decoded = _decodeAny(res);
    if (res.statusCode != 200) {
      if (decoded is Map<String, dynamic>) throw _httpError(res, decoded: decoded);
      throw _httpError(res);
    }
    return decoded;
  }
}