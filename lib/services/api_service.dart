import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://mapachesecure-backend.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }
}
