import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas unitarias para ActividadProvider', () {
    test('1. El estado inicial debe ser vacío y no cargando', () {
      SharedPreferences.setMockInitialValues({});
      final provider = ActividadProvider();

      expect(provider.listaUsoReal.isEmpty, true);
      expect(provider.cargando, false);
      expect(provider.tiempoTotalPantalla.inMilliseconds, 0);
    });

    test(
      '2. tiempoTotalPantalla debe calcular correctamente la suma de la lista en memoria',
      () {
        SharedPreferences.setMockInitialValues({});
        final provider = ActividadProvider();

        // podemos inyectar datos simulados en la lista del proveedor para evaluar el cálculo de duración.
        final app1 = UsageInfo(
          packageName: 'com.whatsapp',
          totalTimeInForeground: '60000',
        ); // 1 minuto
        final app2 = UsageInfo(
          packageName: 'com.roblox.client',
          totalTimeInForeground: '120000',
        ); // 2 minutos

        // Añadimos manualmente a la lista interna usando la referencia del getter para probar la lógica matemática
        provider.listaUsoReal.addAll([app1, app2]);

        expect(provider.tiempoTotalPantalla.inMinutes, 3);
      },
    );

    test(
      '3. sincronizarActividadConServidor realiza la petición HTTP con cabeceras y cuerpo correctos',
      () async {
        // 1. Arrange: Configurar SharedPreferences con credenciales ficticias
        SharedPreferences.setMockInitialValues({
          'hijo_id': 'mapache_hijo_123',
          'auth_token': 'token_secreto_abc',
        });

        final provider = ActividadProvider();

        // Añadimos una app simulada para que pase la condición de lista no vacía
        provider.listaUsoReal.add(
          UsageInfo(
            packageName: 'com.google.android.youtube',
            totalTimeInForeground: '1800000',
          ), // 30 mins
        );

        // Creamos un cliente HTTP falso (Mock) para interceptar la llamada saliente a OnRender
        var peticionVerificada = false;

        // Con esto evitamos que salga a internet real y validamos los datos transmitidos
        final clienteMock = MockClient((request) async {
          if (request.url.toString().contains('/actividad/mapache_hijo_123') &&
              request.headers['Authorization'] == 'Bearer token_secreto_abc' &&
              request.method == 'POST') {
            final body = jsonDecode(request.body);
            if (body['actividades'] != null &&
                body['actividades'][0]['package_name'] ==
                    'com.google.android.youtube') {
              peticionVerificada = true;
            }
          }
          return http.Response(jsonEncode({'status': 'success'}), 200);
        });

        // Sobrescribimos temporalmente el comportamiento de http para que use nuestro mock local
        await http.runWithClient(() async {
          await provider.sincronizarActividadConServidor();
        }, () => clienteMock);

        // 3. Assert: Verificar si la lógica de construcción del JSON del backend fue exitosa
        expect(
          peticionVerificada,
          true,
          reason: "La petición HTTP al backend no se estructuró correctamente.",
        );
      },
    );

    test(
    '4. La lista de actividad debe quedar vacía al limpiarla',
    () {
      SharedPreferences.setMockInitialValues({});
      final provider = ActividadProvider();

      provider.listaUsoReal.add(
        UsageInfo(
          packageName: 'com.youtube.android',
          totalTimeInForeground: '60000',
        ),
      );

      expect(provider.listaUsoReal.isEmpty, false);

      provider.listaUsoReal.clear();

      expect(provider.listaUsoReal.isEmpty, true);
      expect(provider.tiempoTotalPantalla.inMilliseconds, 0);
    },
  );

    test(
      '5. obtenerActividadDelDia termina sin crash cuando UsageStats no está disponible',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ActividadProvider();
        // UsageStats lanza MissingPluginException — el catch(e) lo absorbe
        // Esto cubre las líneas de _cargando=true, DateTime, y el bloque finally
        await provider.obtenerActividadDelDia();
        expect(provider.cargando, false);
        expect(provider.listaUsoReal.isEmpty, true);
      },
    );

    test(
      '6. sincronizarActividadConServidor con credenciales ausentes no hace petición HTTP',
      () async {
        SharedPreferences.setMockInitialValues({}); // Sin hijo_id ni auth_token
        final provider = ActividadProvider();
        var peticionHecha = false;
        await http.runWithClient(() async {
          await provider.sincronizarActividadConServidor();
        }, () => MockClient((req) async {
          peticionHecha = true;
          return http.Response('{}', 200);
        }));
        expect(peticionHecha, false);
      },
    );

    test(
      '7. sincronizarActividadConServidor con respuesta HTTP 500 no lanza excepción',
      () async {
        SharedPreferences.setMockInitialValues({
          'hijo_id': 'uid123',
          'auth_token': 'tok456',
        });
        final provider = ActividadProvider();
        provider.listaUsoReal.add(
          UsageInfo(packageName: 'com.youtube', totalTimeInForeground: '3600000'),
        );
        // No debe lanzar excepción con respuesta de error
        await http.runWithClient(() async {
          await provider.sincronizarActividadConServidor();
        }, () => MockClient((req) async => http.Response('{"error": "internal"}', 500)));
        expect(provider.listaUsoReal.length, 1);
      },
    );

    test(
      '8. sincronizarActividadConServidor con error de red no lanza excepción',
      () async {
        SharedPreferences.setMockInitialValues({
          'hijo_id': 'uid123',
          'auth_token': 'tok456',
        });
        final provider = ActividadProvider();
        provider.listaUsoReal.add(
          UsageInfo(packageName: 'com.instagram.android', totalTimeInForeground: '120000'),
        );
        await http.runWithClient(() async {
          await provider.sincronizarActividadConServidor();
        }, () => MockClient((req) async => throw Exception('Network error')));
        expect(provider.listaUsoReal.length, 1);
      },
    );
  });
}
