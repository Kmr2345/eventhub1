import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

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

    return jsonDecode(res.body);
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