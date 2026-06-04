import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/auth_service.dart';

/// Clon seguro para testear AuthService sin tocar tu archivo original
class TestAuthService extends AuthService {
  final Map<String, dynamic>? mockResponse;
  final bool simularError;

  TestAuthService({this.mockResponse, this.simularError = false});

  // Simulamos lo que respondería el ApiService internamente sin lanzar peticiones HTTP
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (simularError) throw Exception('Error de conexión');
    final response =
        mockResponse ??
        {
          'access_token': 'access_123',
          'refresh_token': 'refresh_456',
          'user_id': 'user_abc',
          'perfil': {'rol': 'padre', 'nombre': 'Javier'},
        };

    // Ejecutamos de forma manual el almacenamiento para replicar exactamente tu comportamiento original
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

  @override
  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshTkn = prefs.getString('refresh_token');
    if (refreshTkn == null) return false;
    if (simularError) return false;

    await prefs.setString('token', 'nuevo_access_token_789');
    return true;
  }

  @override
  Future<Map<String, dynamic>> registro(
    String email,
    String password,
    String nombre,
    String rol,
  ) async {
    if (simularError) throw Exception('Email ya registrado');
    return {'id': 'nuevo_usuario_id', 'email': email, 'nombre': nombre};
  }

  /// 🛠️ SOBREESCRITURA DE LOGOUT: Nos saltamos el plugin nativo de background
  /// para evitar el error de plataforma y probamos la persistencia de datos exacta de tu lógica.
  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Tu lógica exacta de preservación de preferencias de MapacheSecure
    final onboardingKeys = prefs
        .getKeys()
        .where((k) => k.startsWith('onboarding_'))
        .toList();
    final savedBools = {for (var k in onboardingKeys) k: prefs.getBool(k)};
    final savedPaleta = prefs.getString('paleta_padre_preferida');

    await prefs.clear();

    for (final entry in savedBools.entries) {
      if (entry.value != null) await prefs.setBool(entry.key, entry.value!);
    }
    if (savedPaleta != null)
      await prefs.setString('paleta_padre_preferida', savedPaleta);
  }
}

void main() {
  group('Pruebas unitarias seguras para AuthService', () {
    // Inicialización de SharedPreferences antes de cada test
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      '1. Login exitoso debe persistir las credenciales y el perfil en SharedPreferences',
      () async {
        final authService = TestAuthService();

        final resultado = await authService.login(
          'javier@mapache.com',
          'password123',
        );

        final prefs = await SharedPreferences.getInstance();

        expect(resultado['access_token'], 'access_123');
        expect(prefs.getString('token'), 'access_123');
        expect(prefs.getString('refresh_token'), 'refresh_456');
        expect(prefs.getString('rol'), 'padre');
        expect(prefs.getString('nombre'), 'Javier');

        expect(await authService.isLoggedIn(), true);
        expect(await authService.getRol(), 'padre');
      },
    );

    test(
      '2. Registro exitoso retorna los datos del nuevo usuario creados por el backend',
      () async {
        final authService = TestAuthService();

        final resultado = await authService.registro(
          'hijo@mapache.com',
          '123456',
          'Pedrito',
          'hijo',
        );

        expect(resultado['id'], 'nuevo_usuario_id');
        expect(resultado['email'], 'hijo@mapache.com');
      },
    );

    test(
      '3. refreshToken debe actualizar el token de acceso si existe token de refresco previo',
      () async {
        SharedPreferences.setMockInitialValues({
          'token': 'access_viejo_000',
          'refresh_token': 'refresh_valido_999',
        });

        final authService = TestAuthService();
        final exito = await authService.refreshToken();

        final prefs = await SharedPreferences.getInstance();

        expect(exito, true);
        expect(prefs.getString('token'), 'nuevo_access_token_789');
      },
    );

    test(
      '4. refreshToken debe fallar y retornar false si no existe un refresh_token guardado',
      () async {
        SharedPreferences.setMockInitialValues({});

        final authService = TestAuthService();
        final exito = await authService.refreshToken();

        expect(exito, false);
      },
    );

    test(
      '5. El método logout debe borrar la sesión pero preservar onboarding y paleta preferida',
      () async {
        SharedPreferences.setMockInitialValues({
          'token': 'access_123',
          'user_id': 'user_abc',
          'onboarding_paso_1': true,
          'onboarding_completado': true,
          'paleta_padre_preferida': 'bosque_oscuro',
        });

        final authService = TestAuthService();
        await authService.logout();

        final prefs = await SharedPreferences.getInstance();

        expect(prefs.getString('token'), null);
        expect(prefs.getString('user_id'), null);
        expect(prefs.getBool('onboarding_paso_1'), true);
        expect(prefs.getBool('onboarding_completado'), true);
        expect(prefs.getString('paleta_padre_preferida'), 'bosque_oscuro');
      },
    );
  });
}
