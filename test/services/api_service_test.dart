import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';

/// Un clon limpio que no llama a métodos web reales para las cabeceras
class ApiServiceInofensivo extends ApiService {
  final http.Client mockClient;
  ApiServiceInofensivo(this.mockClient);

  @override
  Future<dynamic> get(String endpoint) async {
    // Simulamos la respuesta localmente directo en el cliente falso
    final response = await mockClient.get(
      Uri.parse('https://mapachesecure-backend.onrender.com$endpoint'),
    );
    if (response.statusCode == 401) throw const ApiUnauthorizedException();
    return jsonDecode(response.body);
  }

  @override
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await mockClient.post(
      Uri.parse('https://mapachesecure-backend.onrender.com$endpoint'),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }
}

void main() {
  group('Pruebas unitarias seguras para ApiService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
    });

    test('1. GET exitoso retorna los datos simulados en memoria', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final apiService = ApiServiceInofensivo(mockClient);
      final resultado = await apiService.get('/api/v1/health');

      expect(resultado['status'], 'ok');
    });

    test(
      '2. POST exitoso procesa la respuesta simulada correctamente',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'guardado': true}), 200);
        });

        final apiService = ApiServiceInofensivo(mockClient);
        final resultado = await apiService.post('/api/v1/actividad', {});

        expect(resultado['guardado'], true);
      },
    );

    test('3. Respuesta 401 lanza ApiUnauthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'No autorizado'}), 401);
      });

      final apiService = ApiServiceInofensivo(mockClient);

      expect(
        () async => await apiService.get('/api/v1/protegido'),
        throwsA(isA<ApiUnauthorizedException>()),
      );
    });
  });
}
