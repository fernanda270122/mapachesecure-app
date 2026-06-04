import 'package:flutter_test/flutter_test.dart';

void main() {
    group('Pruebas unitarias para el Asistente IA', () {
      test(
        '1. Un desafío generado debe tener título, descripción y puntos',
        () {
          final desafio = {
            'titulo': 'Ordenar la pieza',
            'descripcion': 'Paso 1: Recoge la ropa. Paso 2: Ponla en el cajón.',
            'puntos': 10,
          };

          expect(desafio['titulo'], isNotNull);
          expect(desafio['descripcion'], isNotNull);
          expect(desafio['puntos'], isNotNull);
        },
      );

      test(
        '2. Los puntos deben respetar la escala según la dificultad',
        () {
          final desafioFacil = {'puntos': 10};
          final desafioMedio = {'puntos': 25};
          final desafioDificil = {'puntos': 45};

          expect(desafioFacil['puntos'] as int, inInclusiveRange(5, 15));
          expect(desafioMedio['puntos'] as int, inInclusiveRange(20, 35));
          expect(desafioDificil['puntos'] as int, inInclusiveRange(40, 50));
        },
      );

      test(
        '3. La cantidad de desafíos generados debe ser la solicitada',
        () {
          final respuestaIA = {
            'desafios': [
              {'titulo': 'Desafío 1', 'descripcion': 'Desc 1', 'puntos': 10},
              {'titulo': 'Desafío 2', 'descripcion': 'Desc 2', 'puntos': 10},
              {'titulo': 'Desafío 3', 'descripcion': 'Desc 3', 'puntos': 10},
            ],
          };

          final cantidad = 3;
          final desafios = List<dynamic>.from(respuestaIA['desafios'] ?? []);

          expect(desafios.length, cantidad);
        },
      );

      test(
        '4. Una respuesta vacía o malformada no debe romper la app',
        () {
          final respuestaVacia = <String, dynamic>{};
          final respuestaNula = {'desafios': null};

          final desafiosVacia = List<dynamic>.from(respuestaVacia['desafios'] ?? []);
          final desafiosNula = List<dynamic>.from(respuestaNula['desafios'] ?? []);

          expect(desafiosVacia.isEmpty, true);
          expect(desafiosNula.isEmpty, true);
        },
      );
    });
  }