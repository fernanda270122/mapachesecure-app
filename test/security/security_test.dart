import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';

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

    test(
      '2. Al eliminar el token de sesión, isLoggedIn retorna false correctamente',
      () async {
        SharedPreferences.setMockInitialValues({'token': 'access_123'});

        final authService = AuthService();
        expect(await authService.isLoggedIn(), true);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');

        expect(await authService.isLoggedIn(), false);
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

    testWidgets(
      '4. PantallaBloqueoScreen no puede cerrarse con el botón de retroceso',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PantallaBloqueoScreen(
              horaInicio: '22:00',
              horaFin: '23:59',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        expect(popScope.canPop, false);
      },
    );
  });
}