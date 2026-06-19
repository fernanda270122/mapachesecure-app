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

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(
        home: DetalleDesafioScreen(desafio: _desafioTest),
      ),
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
  });
}
