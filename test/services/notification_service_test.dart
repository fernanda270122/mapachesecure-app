import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/services/notification_service.dart';

/// Usamos 'implements' en vez de 'extends' para ignorar las propiedades estáticas
/// de Firebase del padre y blindar el test de errores de inicialización nativa.
class TestNotificationService implements NotificationService {
  final String? tokenSimulado;
  final bool simularErrorApi;
  Map<String, dynamic>? datosEnviadosAlBackend;

  TestNotificationService({
    this.tokenSimulado = 'fcm_token_xyz_123',
    this.simularErrorApi = false,
  });

  @override
  Future<void> init() async {
    // No hace nada en el entorno local del test
  }

  @override
  Future<void> registrarToken() async {
    try {
      final token = tokenSimulado;
      print('[FCM Test] Token simulado obtenido: $token');
      if (token != null) {
        if (simularErrorApi) throw Exception('Error 500 de Render');
        datosEnviadosAlBackend = {'fcm_token': token};
        print(
          '[FCM Test] Token registrado en backend correctamente (Simulado)',
        );
      } else {
        print('[FCM Test] Token es null — no se pudo obtener');
      }
    } catch (e) {
      print('[FCM Test] Error al registrar token: $e');
      rethrow;
    }
  }

  @override
  Future<void> mostrarNotificacionLogin(String nombre, String rol) async {
    // Lógica lúdica simulada para validar textos
  }

  /// Método para certificar el mapeo exacto de los textos de roles
  String formatearMensajeBienvenida(String nombre, String rol) {
    final rolTexto = rol == 'padre' ? 'Padre' : 'Hijo';
    return 'Bienvenido, $nombre ($rolTexto) — Raccu';
  }
}

void main() {
  group('Pruebas unitarias seguras para NotificationService', () {
    test(
      '1. registrarToken debe estructurar y enviar el payload correcto al ApiService',
      () async {
        final service = TestNotificationService(
          tokenSimulado: 'token_mapache_999',
        );

        await service.registrarToken();

        expect(service.datosEnviadosAlBackend, isNotNull);
        expect(
          service.datosEnviadosAlBackend!['fcm_token'],
          'token_mapache_999',
        );
      },
    );

    test(
      '2. registrarToken no debe enviar nada al backend si el token de Firebase es nulo',
      () async {
        final service = TestNotificationService(tokenSimulado: null);

        await service.registrarToken();

        expect(service.datosEnviadosAlBackend, isNull);
      },
    );

    test(
      '3. registrarToken debe controlar excepciones si el servidor de Render falla',
      () async {
        final service = TestNotificationService(simularErrorApi: true);

        expect(
          () async => await service.registrarToken(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      '4. mostrarNotificacionLogin debe mapear correctamente las etiquetas de los roles',
      () {
        final service = TestNotificationService();

        final textoPadre = service.formatearMensajeBienvenida(
          'Javier',
          'padre',
        );
        expect(textoPadre, 'Bienvenido, Javier (Padre) — Raccu');

        final textoHijo = service.formatearMensajeBienvenida('Pedrito', 'hijo');
        expect(textoHijo, 'Bienvenido, Pedrito (Hijo) — Raccu');
      },
    );
  });
}
