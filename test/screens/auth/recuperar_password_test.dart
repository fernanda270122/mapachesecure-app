import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/recuperar_password.dart';
import 'package:mapachesecure_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.testClient = MockClient((req) async => http.Response('{"ok": true}', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  Widget wrap() => const MaterialApp(home: RecuperarPassword());

  group('Pruebas para RecuperarPassword', () {
    testWidgets('1. Muestra Recuperar contraseña en el AppBar', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.text('Recuperar contraseña'), findsOneWidget);
    });

    testWidgets('2. Muestra el campo de correo electronico', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
    });

    testWidgets('3. Muestra el boton ENVIAR CORREO', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.text('ENVIAR CORREO'), findsOneWidget);
    });

    testWidgets('4. Muestra el icono de email en el campo', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('5. Tap en ENVIAR sin correo no hace nada', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ENVIAR CORREO'));
      await tester.pumpAndSettle();
      // Sin correo no debe cambiar el estado ni mostrar confirmacion
      expect(find.text('ENVIAR CORREO'), findsOneWidget);
      expect(find.textContaining('¡Correo enviado!'), findsNothing);
    });

    testWidgets('6. Con correo valido y API exitosa muestra confirmacion', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'test@test.com');
      await tester.tap(find.text('ENVIAR CORREO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('¡Correo enviado!'), findsOneWidget);
    });

    testWidgets('7. Con correo valido y API fallida muestra SnackBar de error', (tester) async {
      ApiService.testClient = MockClient((req) async => throw Exception('Sin conexion'));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'test@test.com');
      await tester.tap(find.text('ENVIAR CORREO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Error'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('8. Contiene un Scaffold como raiz de la pantalla', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
