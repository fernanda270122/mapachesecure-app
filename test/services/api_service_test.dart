import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';

ApiService _servicio(MockClient client) => ApiService(client: client);

void main() {
  group('Pruebas unitarias para ApiService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
    });

    // ── GET ──────────────────────────────────────────────────────────────────

    test('1. GET 200 retorna el cuerpo decodificado', () async {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'status': 'ok'}), 200)),
      );
      final result = await api.get('/health');
      expect(result['status'], 'ok');
    });

    test('2. GET 401 lanza ApiUnauthorizedException', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'detail': 'No autorizado'}), 401)),
      );
      expect(() => api.get('/protegido'), throwsA(isA<ApiUnauthorizedException>()));
    });

    test('3. GET 500 con detail lanza Exception con el mensaje del servidor', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'detail': 'Error interno'}), 500)),
      );
      expect(
        () => api.get('/algo'),
        throwsA(predicate<Exception>((e) => e.toString().contains('Error interno'))),
      );
    });

    test('4. GET 404 sin campo detail lanza Exception genérica', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({}), 404)),
      );
      expect(() => api.get('/no-existe'), throwsA(isA<Exception>()));
    });

    test('5. GET incluye Authorization header cuando hay token en prefs', () async {
      SharedPreferences.setMockInitialValues({'token': 'mi_token_secreto'});
      Map<String, String>? headers;
      final api = _servicio(MockClient((req) async {
        headers = req.headers;
        return http.Response(jsonEncode({'ok': true}), 200);
      }));
      await api.get('/algo');
      expect(headers?['Authorization'], 'Bearer mi_token_secreto');
    });

    test('6. GET no incluye Authorization header cuando no hay token en prefs', () async {
      SharedPreferences.setMockInitialValues({});
      Map<String, String>? headers;
      final api = _servicio(MockClient((req) async {
        headers = req.headers;
        return http.Response(jsonEncode({'ok': true}), 200);
      }));
      await api.get('/algo');
      expect(headers?.containsKey('Authorization'), false);
    });

    // ── POST ─────────────────────────────────────────────────────────────────

    test('7. POST 200 retorna el cuerpo decodificado', () async {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'guardado': true}), 201)),
      );
      final result = await api.post('/actividad', {'dato': 1});
      expect(result['guardado'], true);
    });

    test('8. POST 400 con detail lanza Exception', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'detail': 'Datos inválidos'}), 400)),
      );
      expect(
        () => api.post('/actividad', {}),
        throwsA(predicate<Exception>((e) => e.toString().contains('Datos inválidos'))),
      );
    });

    test('9. POST con auth=false no incluye Authorization header', () async {
      Map<String, String>? headers;
      final api = _servicio(MockClient((req) async {
        headers = req.headers;
        return http.Response(jsonEncode({'ok': true}), 200);
      }));
      await api.post('/auth/login', {'email': 'x'}, auth: false);
      expect(headers?.containsKey('Authorization'), false);
    });

    // ── PUT ──────────────────────────────────────────────────────────────────

    test('10. PUT 200 retorna los datos actualizados', () async {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'actualizado': true}), 200)),
      );
      final result = await api.put('/usuario/1', {'nombre': 'Nuevo'});
      expect(result['actualizado'], true);
    });

    test('11. PUT 401 lanza ApiUnauthorizedException', () {
      final api = _servicio(
        MockClient((_) async => http.Response('', 401)),
      );
      expect(() => api.put('/usuario/1', {}), throwsA(isA<ApiUnauthorizedException>()));
    });

    test('12. PUT 500 lanza Exception', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'detail': 'Fallo del servidor'}), 500)),
      );
      expect(() => api.put('/usuario/1', {}), throwsA(isA<Exception>()));
    });

    // ── DELETE ───────────────────────────────────────────────────────────────

    test('13. DELETE 200 retorna confirmación', () async {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'eliminado': true}), 200)),
      );
      final result = await api.delete('/usuario/1');
      expect(result['eliminado'], true);
    });

    test('14. DELETE 401 lanza ApiUnauthorizedException', () {
      final api = _servicio(
        MockClient((_) async => http.Response('', 401)),
      );
      expect(() => api.delete('/usuario/1'), throwsA(isA<ApiUnauthorizedException>()));
    });

    test('15. DELETE 500 lanza Exception', () {
      final api = _servicio(
        MockClient((_) async => http.Response(jsonEncode({'detail': 'Error al eliminar'}), 500)),
      );
      expect(() => api.delete('/usuario/1'), throwsA(isA<Exception>()));
    });
  });
}
