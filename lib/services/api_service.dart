import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    Map<String, dynamic> decoded;
    try {
      decoded = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw Exception('Invalid JSON response (${res.statusCode}): ${res.body}');
    }

    if (res.statusCode != 200) {
      final msg = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Registration failed (${res.statusCode})';
      throw Exception(msg);
    }

    return decoded;
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    Map<String, dynamic> decoded;
    try {
      decoded = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      throw Exception('Invalid JSON response (${res.statusCode}): ${res.body}');
    }

    if (res.statusCode != 200) {
      final msg = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Login failed (${res.statusCode})';
      throw Exception(msg);
    }

    if (decoded['token'] == null || decoded['user'] == null) {
      throw Exception('Unexpected login response: missing token/user');
    }

    return decoded;
  }

  // GET EVENTS
  static Future<List> getEvents(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {'Authorization': token},
    );
    return jsonDecode(res.body);
  }
}