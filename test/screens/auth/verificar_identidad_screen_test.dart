import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/verificar_identidad_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para VerificarIdentidadScreen', () {
    testWidgets(
      '1. Muestra "Verificación" en el AppBar',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Verificación'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el título "Verificación de Rostro"',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Verificación de Rostro'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra el ícono de reconocimiento facial',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.face_unlock_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '4. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });
}
