import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas funcionales — MapacheSecure', () {
    testWidgets(
      '1. Login fallido muestra mensaje de error al usuario',
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

    testWidgets(
      '2. Seleccionar un avatar lo marca visualmente como seleccionado',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({'user_id': 'hijo_123'});

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => TemaProvider(),
            child: const MaterialApp(home: AvatarScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final haySeleccionado = containers.any((c) {
          final deco = c.decoration;
          if (deco is BoxDecoration && deco.border != null) {
            final border = deco.border as Border;
            return border.top.color == Colors.deepPurple;
          }
          return false;
        });

        expect(haySeleccionado, true);
      },
    );

    testWidgets(
      '3. PantallaBloqueoScreen muestra el horario y el mensaje completo al usuario',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: PantallaBloqueoScreen(
              horaInicio: '20:00',
              horaFin: '22:00',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('App bloqueada'), findsOneWidget);
        expect(find.text('Horario de bloqueo: 20:00 - 22:00'), findsOneWidget);
        expect(find.text('Vuelve cuando termine el bloqueo 🦝'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Flujo de recuperar contraseña navega a la pantalla correcta',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Olvidé mi contraseña'));
        await tester.pumpAndSettle();

        expect(find.text('Recuperar contraseña'), findsOneWidget);
      },
    );
  });
}