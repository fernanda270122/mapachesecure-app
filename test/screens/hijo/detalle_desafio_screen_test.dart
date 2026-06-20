import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/detalle_desafio_screen.dart';

const _desafioTest = {
  'id': 'test-id-123',
  'titulo': 'Haz 10 flexiones',
  'descripcion': 'Realiza 10 flexiones y sube la foto como evidencia.',
  'tipo': 'fisico',
  'puntos': 50,
  'dificultad': 'medio',
  'esta_activo': true,
};

Widget _wrap([Map<String, dynamic> desafio = _desafioTest]) =>
    ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: MaterialApp(home: DetalleDesafioScreen(desafio: desafio)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para DetalleDesafioScreen', () {
    testWidgets(
      '1. Muestra el título del desafío en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Haz 10 flexiones'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el badge de dificultad "NIVEL: MEDIO"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.textContaining('NIVEL:'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra la descripción del desafío',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('Realiza 10 flexiones y sube la foto como evidencia.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4. Muestra la recompensa en puntos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.textContaining('50 pts'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra el placeholder para la cámara',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('Toca para sacar la foto de evidencia'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Muestra el botón "ENVIAR DESAFÍO"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('ENVIAR DESAFÍO'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Tap ENVIAR sin foto muestra SnackBar de advertencia',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.text('ENVIAR DESAFÍO'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text('¡Saca una foto para demostrar que cumpliste!'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '8. Dificultad "facil" muestra badge verde con texto NIVEL: FACIL',
      (tester) async {
        await tester.pumpWidget(_wrap(const {
          'id': '1',
          'titulo': 'Reto fácil',
          'descripcion': 'Descripción fácil.',
          'tipo': 'cognitivo',
          'puntos': 10,
          'dificultad': 'facil',
        }));
        await tester.pumpAndSettle();
        expect(find.textContaining('NIVEL: FACIL'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Dificultad "dificil" muestra badge rojo con texto NIVEL: DIFICIL',
      (tester) async {
        await tester.pumpWidget(_wrap(const {
          'id': '2',
          'titulo': 'Reto difícil',
          'descripcion': 'Descripción difícil.',
          'tipo': 'orden',
          'puntos': 100,
          'dificultad': 'dificil',
        }));
        await tester.pumpAndSettle();
        expect(find.textContaining('NIVEL: DIFICIL'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Dificultad nula usa texto default "NORMAL" en el badge',
      (tester) async {
        await tester.pumpWidget(_wrap(const {
          'id': '3',
          'titulo': 'Reto sin dificultad',
          'descripcion': 'Sin dificultad asignada.',
          'tipo': 'general',
          'puntos': 20,
        }));
        await tester.pumpAndSettle();
        expect(find.textContaining('NIVEL: NORMAL'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Título nulo en desafio usa texto por defecto en AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap(const {
          'id': '4',
          'descripcion': 'Sin título asignado.',
          'tipo': 'general',
          'puntos': 5,
          'dificultad': 'medio',
        }));
        await tester.pumpAndSettle();
        expect(find.text('Resolver Desafío'), findsOneWidget);
      },
    );
  });
}
