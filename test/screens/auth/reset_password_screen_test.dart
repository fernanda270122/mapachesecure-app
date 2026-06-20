import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/reset_password_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => const MaterialApp(
      home: ResetPasswordScreen(accessToken: 'token-de-prueba'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.testClient = MockClient((req) async => http.Response('{"ok": true}', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  group('Pruebas para ResetPasswordScreen', () {
    testWidgets('1. Muestra el titulo Nueva contrasena en el AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // El hint del campo también dice "Nueva contraseña", por eso usamos descendant
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Nueva contraseña')),
        findsOneWidget,
      );
    });

    testWidgets('2. Muestra los campos de nueva y confirmar contrasena', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('3. Muestra el boton CAMBIAR CONTRASENA', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('CAMBIAR CONTRASEÑA'), findsOneWidget);
    });

    testWidgets('4. Muestra SnackBar cuando las contrasenas no coinciden', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'contrasena1');
      await tester.enterText(find.byType(TextField).last, 'contrasena2');
      await tester.tap(find.text('CAMBIAR CONTRASEÑA'));
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('5. Muestra SnackBar cuando la contrasena tiene menos de 6 caracteres', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.enterText(find.byType(TextField).last, 'abc');
      await tester.tap(find.text('CAMBIAR CONTRASEÑA'));
      await tester.pumpAndSettle();
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('6. Cambio exitoso muestra mensaje de confirmacion', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nueva123');
      await tester.enterText(find.byType(TextField).last, 'nueva123');
      await tester.tap(find.text('CAMBIAR CONTRASEÑA'));
      // Múltiples pumps: el CircularProgressIndicator bloquea pumpAndSettle;
      // se necesitan varios ciclos para que SharedPreferences + MockClient resuelvan
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('¡Contraseña actualizada! Ya puedes iniciar sesión.'),
        findsOneWidget,
      );
    });

    testWidgets('7. Muestra icono de check al completar el cambio', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nueva123');
      await tester.enterText(find.byType(TextField).last, 'nueva123');
      await tester.tap(find.text('CAMBIAR CONTRASEÑA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('8. Error de API muestra SnackBar de error', (tester) async {
      ApiService.testClient = MockClient(
        (req) async => http.Response('{"detail": "Error del servidor"}', 500),
      );
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nueva123');
      await tester.enterText(find.byType(TextField).last, 'nueva123');
      await tester.tap(find.text('CAMBIAR CONTRASEÑA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Error al cambiar la contraseña'), findsOneWidget);
    });
  });
}
