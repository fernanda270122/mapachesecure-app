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
      if (response['refresh_token'] != null) {
        await prefs.setString('refresh_token', response['refresh_token']);
      }
      await prefs.setString('user_id', response['user_id']);
      await prefs.setString('rol', response['perfil']['rol']);
      await prefs.setString('nombre', response['perfil']['nombre']);
    }
    return response;
  }

  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshTkn = prefs.getString('refresh_token');
    if (refreshTkn == null) return false;
    try {
      final response = await _api.post(
        '/auth/refresh',
        {'refresh_token': refreshTkn},
        auth: false,
      );
      if (response['access_token'] != null) {
        await prefs.setString('token', response['access_token']);
        if (response['refresh_token'] != null) {
          await prefs.setString('refresh_token', response['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
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
    // Preservar preferencias de onboarding y tema del padre entre sesiones
    final onboardingKeys = prefs.getKeys().where((k) => k.startsWith('onboarding_')).toList();
    final savedBools = {for (var k in onboardingKeys) k: prefs.getBool(k)};
    final savedPaleta = prefs.getString('paleta_padre_preferida');
    await prefs.clear();
    for (final entry in savedBools.entries) {
      if (entry.value != null) await prefs.setBool(entry.key, entry.value!);
    }
    if (savedPaleta != null) await prefs.setString('paleta_padre_preferida', savedPaleta);
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
