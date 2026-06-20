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

    testWidgets(
      '5. Muestra el texto Toca aqui para tomar la foto',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Toca aquí para tomar la foto'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra el boton Escanear Rostro',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Escanear Rostro'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Muestra el boton de explicacion Por que necesitamos esto',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('¿Por qué necesitamos esto?'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Tap en Por que necesitamos esto abre dialogo de explicacion',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('¿Por qué necesitamos esto?'));
        await tester.pumpAndSettle();
        expect(find.text('¿Por qué verificamos tu rostro?'), findsOneWidget);
        expect(find.text('Entendido'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Tap en Entendido cierra el dialogo',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('¿Por qué necesitamos esto?'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();
        expect(find.text('¿Por qué verificamos tu rostro?'), findsNothing);
      },
    );

    testWidgets(
      '10. Muestra el icono de rostro en la zona de captura',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.face_retouching_natural_rounded), findsOneWidget);
      },
    );
  });
}
