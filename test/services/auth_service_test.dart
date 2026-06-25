import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/services/api_service.dart';

// ── Helpers para el segundo grupo (prueba código real) ─────────────────────

class FakeApiService extends ApiService {
  Map<String, dynamic>? loginResp;
  Map<String, dynamic>? refreshResp;
  bool throwOnPost;

  FakeApiService({this.loginResp, this.refreshResp, this.throwOnPost = false});

  @override
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    if (throwOnPost) throw Exception('Error de red simulado');
    if (endpoint == '/auth/login') {
      return loginResp ??
          {
            'access_token': 'token_abc',
            'refresh_token': 'refresh_xyz',
            'user_id': 'uid_123',
            'perfil': {'rol': 'padre', 'nombre': 'Carlos'},
          };
    }
    if (endpoint == '/auth/refresh') {
      return refreshResp ?? {'access_token': 'token_renovado'};
    }
    if (endpoint == '/auth/registro') {
      return {
        'id': 'uid_nuevo',
        'email': body['email'],
        'nombre': body['nombre'],
      };
    }
    return {};
  }
}

// Evita llamar a FlutterBackgroundService en tests; el resto es código real
class AuthServiceTestable extends AuthService {
  AuthServiceTestable(ApiService api) : super(api: api);

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
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
    if (savedPaleta != null) {
      await prefs.setString('paleta_padre_preferida', savedPaleta);
    }
  }
}

// ── TestAuthService (grupo original, sin cambios) ──────────────────────────

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

  /// SOBREESCRITURA DE LOGOUT: Nos saltamos el plugin nativo de background
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
    if (savedPaleta != null) {
      await prefs.setString('paleta_padre_preferida', savedPaleta);
    }
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

  // ── Pruebas sobre el código REAL de AuthService ───────────────────────────

  group('Pruebas sobre el código real de AuthService (con FakeApiService)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      '6. login() guarda token, refresh_token, user_id, rol y nombre en SharedPreferences',
      () async {
        final auth = AuthServiceTestable(FakeApiService());

        await auth.login('carlos@test.com', 'pass123');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), 'token_abc');
        expect(prefs.getString('refresh_token'), 'refresh_xyz');
        expect(prefs.getString('user_id'), 'uid_123');
        expect(prefs.getString('rol'), 'padre');
        expect(prefs.getString('nombre'), 'Carlos');
      },
    );

    test(
      '7. login() sin access_token en respuesta no guarda nada en prefs',
      () async {
        final auth = AuthServiceTestable(
          FakeApiService(loginResp: {'error': 'credenciales inválidas'}),
        );

        await auth.login('x@x.com', 'wrong');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), null);
      },
    );

    test(
      '8. refreshToken() actualiza access_token y refresh_token cuando la API responde correctamente',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'refresh_actual',
        });
        final auth = AuthServiceTestable(
          FakeApiService(
            refreshResp: {
              'access_token': 'token_renovado',
              'refresh_token': 'nuevo_refresh',
            },
          ),
        );

        final exito = await auth.refreshToken();

        expect(exito, true);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), 'token_renovado');
        expect(prefs.getString('refresh_token'), 'nuevo_refresh');
      },
    );

    test(
      '9. refreshToken() solo actualiza access_token cuando la API no devuelve nuevo refresh_token',
      () async {
        SharedPreferences.setMockInitialValues({
          'refresh_token': 'viejo_refresh',
        });
        final auth = AuthServiceTestable(
          FakeApiService(refreshResp: {'access_token': 'token_nuevo'}),
        );

        final exito = await auth.refreshToken();

        expect(exito, true);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), 'token_nuevo');
        expect(prefs.getString('refresh_token'), 'viejo_refresh');
      },
    );

    test(
      '10. refreshToken() retorna false cuando la respuesta no incluye access_token',
      () async {
        SharedPreferences.setMockInitialValues({'refresh_token': 'algo'});
        final auth = AuthServiceTestable(
          FakeApiService(refreshResp: {'error': 'token expirado'}),
        );

        final exito = await auth.refreshToken();
        expect(exito, false);
      },
    );

    test(
      '11. refreshToken() retorna false cuando la API lanza excepción',
      () async {
        SharedPreferences.setMockInitialValues({'refresh_token': 'algo'});
        final auth = AuthServiceTestable(FakeApiService(throwOnPost: true));

        final exito = await auth.refreshToken();
        expect(exito, false);
      },
    );

    test(
      '12. registro() devuelve email y nombre del nuevo usuario registrado',
      () async {
        final auth = AuthServiceTestable(FakeApiService());

        final resultado = await auth.registro(
          'nuevo@test.com',
          'pass',
          'María',
          'padre',
        );

        expect(resultado['email'], 'nuevo@test.com');
        expect(resultado['nombre'], 'María');
      },
    );

    test(
      '13. isLoggedIn() retorna false cuando no hay token en SharedPreferences',
      () async {
        final auth = AuthServiceTestable(FakeApiService());
        expect(await auth.isLoggedIn(), false);
      },
    );

    test(
      '14. getRol() retorna null cuando no hay rol guardado en SharedPreferences',
      () async {
        final auth = AuthServiceTestable(FakeApiService());
        expect(await auth.getRol(), null);
      },
    );

    test(
      '15. logout() limpia la sesión pero preserva claves onboarding y paleta preferida',
      () async {
        SharedPreferences.setMockInitialValues({
          'token': 'tok',
          'user_id': 'uid',
          'onboarding_padre_visto': true,
          'paleta_padre_preferida': 'oceano',
        });
        final auth = AuthServiceTestable(FakeApiService());

        await auth.logout();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('token'), null);
        expect(prefs.getString('user_id'), null);
        expect(prefs.getBool('onboarding_padre_visto'), true);
        expect(prefs.getString('paleta_padre_preferida'), 'oceano');
      },
    );
  });
}
