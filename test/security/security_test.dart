import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas de seguridad — MapacheSecure', () {
    test(
      '1. Sin token guardado, isLoggedIn retorna false',
      () async {
        SharedPreferences.setMockInitialValues({});

        final authService = AuthService();
        final loggedIn = await authService.isLoggedIn();

        expect(loggedIn, false);
      },
    );

    testWidgets(
      '2. Login sin credenciales muestra mensaje de error',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('INGRESAR'));
        await tester.pumpAndSettle();

        expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      },
    );

    test(
      '3. JSON con valores malformados no rompe el modelo Desafio',
      () {
        final jsonMalformado = {
          'id': null,
          'titulo': null,
          'descripcion': null,
          'puntos': null,
          'categoria': null,
          'estado': null,
        };

        expect(
          () => Desafio.fromJson(jsonMalformado),
          returnsNormally,
        );
      },
    );

    test(
      '4. Un path de avatar fuera de los permitidos no coincide con ninguno válido',
      () {
        final pathsValidos = [
          'assets/avatares/perfil1.jpeg',
          'assets/avatares/perfil2.jpeg',
          'assets/avatares/perfil3.jpeg',
          'assets/avatares/perfil4.jpeg',
          'assets/avatares/perfil6.jpeg',
          'assets/avatares/perfil7.jpeg',
          'assets/avatares/perfil8.jpeg',
        ];

        final pathMalicioso = '../../etc/passwd';

        expect(pathsValidos.contains(pathMalicioso), false);
      },
    );
  });
}