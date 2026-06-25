import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/models/desafio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_test'});
  });

  group('Pruebas para el Asistente IA — MapacheSecure', () {
    test(
      '1. POST /ia/generar retorna lista de desafíos correctamente estructurados',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/ia/generar')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'ia_1',
                  'titulo': 'Ordenar la pieza',
                  'descripcion': 'Recoge tu ropa',
                  'puntos': 10,
                  'categoria': 'hogar',
                  'estado': 'activo',
                },
                {
                  'id': 'ia_2',
                  'titulo': 'Leer 15 minutos',
                  'descripcion': 'Lee un libro',
                  'puntos': 20,
                  'categoria': 'educacion',
                  'estado': 'activo',
                },
                {
                  'id': 'ia_3',
                  'titulo': 'Hacer la cama',
                  'descripcion': 'Ordena tu cama',
                  'puntos': 15,
                  'categoria': 'hogar',
                  'estado': 'activo',
                },
              ]),
              200,
            );
          }
          return http.Response('{}', 404);
        });

        late dynamic resultado;
        await http.runWithClient(() async {
          final api = ApiService();
          resultado = await api.post('/ia/generar', {
            'categoria': 'hogar',
            'dificultad': 'facil',
          });
        }, () => mockClient);

        expect(resultado, isList);
        expect((resultado as List).length, 3);
      },
    );

    test(
      '2. Los desafíos generados por la IA se parsean correctamente como modelo Desafio',
      () {
        final jsonIA = {
          'id': 'ia_001',
          'titulo': 'Ayudar en la cocina',
          'descripcion': 'Paso 1: Lava los platos. Paso 2: Seca y guarda.',
          'categoria': 'hogar',
          'puntos': 25,
          'tiempo_estimado_minutos': 20,
          'estado': 'activo',
          'hijo_id': 'hijo_test',
        };

        final desafio = Desafio.fromJson(jsonIA);

        expect(desafio.titulo, 'Ayudar en la cocina');
        expect(desafio.estaActivo, true);
        expect(desafio.tiempoTexto, '20 min');
        expect(desafio.puntos, 25);
      },
    );

    test(
      '3. Respuesta vacía de /ia/generar retorna lista vacía sin error',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode([]), 200);
        });

        late dynamic resultado;
        await http.runWithClient(() async {
          final api = ApiService();
          resultado = await api.post('/ia/generar', {'categoria': 'deporte'});
        }, () => mockClient);

        expect(resultado, isList);
        expect((resultado as List).isEmpty, true);
      },
    );

    test(
      '4. Un desafío de IA con campos mínimos no rompe el modelo Desafio',
      () {
        final jsonMinimo = {
          'id': 'ia_min',
          'titulo': 'Desafío simple',
          'descripcion': null,
          'puntos': null,
          'categoria': null,
          'estado': null,
        };

        expect(() => Desafio.fromJson(jsonMinimo), returnsNormally);
      },
    );
  });
}
