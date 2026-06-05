import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';
import 'package:mapachesecure_app/screens/padre/consejos_padres_screen.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Pruebas de humo — pantallas críticas', () {
      testWidgets(
        '1. LoginScreen renderiza sin errores',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: LoginScreen()),
          );
          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsOneWidget);
        },
      );

      testWidgets(
        '2. AvatarScreen renderiza sin errores',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => TemaProvider(),
              child: const MaterialApp(home: AvatarScreen()),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsOneWidget);
        },
      );

      testWidgets(
        '3. PantallaBloqueoScreen renderiza sin errores',
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

          expect(find.byType(Scaffold), findsOneWidget);
        },
      );

      testWidgets(
        '4. ConsejosPadresScreen renderiza sin errores',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(360, 690),
              builder: (_, __) => ChangeNotifierProvider(
                create: (_) => TemaPadreProvider(),
                child: const MaterialApp(home: ConsejosPadresScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(Scaffold), findsOneWidget);
        },
      );
    });
  }