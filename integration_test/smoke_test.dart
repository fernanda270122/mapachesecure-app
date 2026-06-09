import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/padre/agregar_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/configurar_hijo.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';

Widget _app(Widget screen) => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => TemaPadreProvider()..cargarTemaPadre()),
          ChangeNotifierProvider(create: (_) => TemaProvider()..cargar()),
        ],
        child: MaterialApp(home: screen),
      ),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': 'token_mock',
      'user_id': 'hijo_001',
    });
  });

  testWidgets('1. Panel del padre: registrar un hijo', (tester) async {
    await tester.pumpWidget(_app(const AgregarHijoScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Agregar Hij@'), findsOneWidget);

    // Campos de texto: nombre, correo, contraseña, edad
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Catalina');
    await tester.enterText(campos.at(1), '3ratoncitasbellas@gmail.com');
    await tester.enterText(campos.at(2), 'clave1234');
    await tester.enterText(campos.at(3), '14');
    await tester.pump(const Duration(milliseconds: 500));

    // Dropdown sexo → Femenino
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Femenino').last);
    await tester.pumpAndSettle();

    // Dropdown nivel escolar → Media
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Media').last);
    await tester.pumpAndSettle();

    // Dropdown personalidad → Curioso/a
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curioso/a').last);
    await tester.pumpAndSettle();

    // Chips de intereses
    await tester.tap(find.text('Música'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tecnología'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Deportes'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Catalina'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('2. Panel del padre: ver protección de Catalina', (tester) async {
    final mockVacio = MockClient((request) async {
      if (request.url.path.contains('/apps/')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.contains('/bloqueos/')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response(jsonEncode({}), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(
        ConfigurarHijoScreen(
          hijo: const {'id': 'hijo_001', 'nombre': 'Catalina'},
        ),
      ));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Configurar a Catalina'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Bloqueos activos'), findsOneWidget);
      expect(find.text('Apps a bloquear'), findsOneWidget);

      // Activa el bloqueo total
      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(seconds: 2));

      // Aparece el diálogo de aviso
      expect(
        find.textContaining('2 a 3 minutos'),
        findsOneWidget,
      );
    }, () => mockVacio);
  });

  testWidgets('3. Panel del hijo: app bloqueada y no puede salir',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PantallaBloqueoScreen(horaInicio: '20:00', horaFin: '22:00'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('App bloqueada'), findsOneWidget);
    expect(find.text('Horario de bloqueo: 20:00 - 22:00'), findsOneWidget);
    expect(find.text('Vuelve cuando termine el bloqueo 🦝'), findsOneWidget);

    // Intenta salir — la pantalla no lo permite
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.maybePop();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('App bloqueada'), findsOneWidget);
  });

  testWidgets('4. Panel del hijo: elegir foto de perfil', (tester) async {
    await tester.pumpWidget(_app(const AvatarScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Elige tu avatar'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Toca la primera foto de perfil disponible
    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pump(const Duration(seconds: 1));
  });
}
