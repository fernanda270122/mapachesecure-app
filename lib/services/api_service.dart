import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiUnauthorizedException implements Exception {
  const ApiUnauthorizedException();
}

class ApiService {
  static const String _baseUrl = 'https://mapachesecure-backend.onrender.com';
  final http.Client _client;

  // Test-only: set a global mock client to avoid real network calls in unit tests.
  // Has no effect in production (stays null).
  static http.Client? testClient;

  ApiService({http.Client? client}) : _client = client ?? testClient ?? http.Client();

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
    final response = await _client.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) throw const ApiUnauthorizedException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error del servidor (${response.statusCode})');
    }
    return jsonDecode(response.body);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['detail'] ?? 'Error del servidor (${response.statusCode})',
      );
    }
    return data;
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 401) throw const ApiUnauthorizedException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error del servidor (${response.statusCode})');
    }
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) throw const ApiUnauthorizedException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error del servidor (${response.statusCode})');
    }
    return jsonDecode(response.body);
  }
}
