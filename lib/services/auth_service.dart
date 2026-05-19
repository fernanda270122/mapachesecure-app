import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);
    if (response['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['access_token']);
      await prefs.setString('user_id', response['user_id']);
      await prefs.setString('rol', response['perfil']['rol']);
      await prefs.setString('nombre', response['perfil']['nombre']);
    }
    return response;
  }

  Future<Map<String, dynamic>> registro(
    String email,
    String password,
    String nombre,
    String rol,
  ) async {
    return await _api.post('/auth/registro', {
      'email': email,
      'password': password,
      'nombre': nombre,
      'rol': rol,
    }, auth: false);
  }

  Future<void> logout() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService"); 
    }
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().where((k) => k.startsWith('onboarding_')).toList();
    final saved = {for (var k in allKeys) k: prefs.getBool(k)};
    await prefs.clear();
    for (final entry in saved.entries) {
      if (entry.value != null) await prefs.setBool(entry.key, entry.value!);
    }
  }

  Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}
