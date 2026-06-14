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
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/padre/agregar_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/desafios_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/configurar_hijo.dart';
import 'package:mapachesecure_app/screens/padre/recompensas_screen.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';
import 'package:mapachesecure_app/screens/hijo/seleccion_avatar_screen.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';

// _hijoId hardcodeado: 3ratoncitasbellas@gmail.com en Supabase
String _hijoToken = 'token_mock';
String _hijoId = '03238377-e316-4b21-9fe2-07a47d09ab2a';
String _padreToken = 'token_mock';

Widget _app(Widget screen) => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MultiProvider(
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

  // Dos logins al inicio: hijo (para sus pantallas) y padre (para gestionar desafíos).
  // Si falla (sin internet / rate limit) los tests corren igual pero sin datos reales.
  setUpAll(() async {
    debugPrint('🦝 setUpAll: iniciando logins...');

    // 1. Login hijo
    try {
      final hijoResp = await http.post(
        Uri.parse('https://mapachesecure-backend.onrender.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': '3ratoncitasbellas@gmail.com',
          'password': 'clave1234',
        }),
      );
      debugPrint('🦝 login hijo status: ${hijoResp.statusCode}');
      if (hijoResp.statusCode == 200) {
        final d = jsonDecode(hijoResp.body) as Map<String, dynamic>;
        _hijoToken = d['access_token']?.toString() ?? _hijoToken;
        debugPrint('🦝 hijoToken obtenido: ${_hijoToken != 'token_mock'}');
      } else {
        debugPrint('🦝 login hijo body: ${hijoResp.body}');
      }
    } catch (e) {
      debugPrint('🦝 login hijo ERROR: $e');
    }

    // 2. Login padre
    try {
      final padreResp = await http.post(
        Uri.parse('https://mapachesecure-backend.onrender.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'fer.arrano.munoz@gmail.com',
          'password': 'cata1234',
        }),
      );
      debugPrint('🦝 login padre status: ${padreResp.statusCode}');
      if (padreResp.statusCode == 200) {
        final d = jsonDecode(padreResp.body) as Map<String, dynamic>;
        _padreToken = d['access_token']?.toString() ?? _padreToken;
        debugPrint('🦝 padreToken obtenido: ${_padreToken != 'token_mock'}');
      } else {
        debugPrint('🦝 login padre body: ${padreResp.body}');
      }
    } catch (e) {
      debugPrint('🦝 login padre ERROR: $e');
    }

    // 3. Crear desafíos de prueba en Supabase para que aparezcan en las pantallas.
    //    Usa el token del padre y el ID real del hijo.
    if (_padreToken != 'token_mock' && _hijoId != 'hijo_001') {
      final desafios = [
        {
          'titulo': 'Leer 10 páginas',
          'descripcion': 'Lee 10 páginas de un libro de tu elección',
          'puntos': 20,
          'tipo': 'cognitiva',
          'dificultad': 'facil',
          'hijo_id': _hijoId,
          'esta_activo': true,
        },
        {
          'titulo': 'Hacer 20 sentadillas',
          'descripcion': 'Realiza 20 sentadillas antes de dormir',
          'puntos': 30,
          'tipo': 'fisica',
          'dificultad': 'facil',
          'hijo_id': _hijoId,
          'esta_activo': true,
        },
        {
          'titulo': 'Ordenar tu habitación',
          'descripcion': 'Deja tu cuarto ordenado antes de cenar',
          'puntos': 25,
          'tipo': 'hogar',
          'dificultad': 'facil',
          'hijo_id': _hijoId,
          'esta_activo': true,
        },
      ];
      for (final d in desafios) {
        try {
          await http.post(
            Uri.parse(
                'https://mapachesecure-backend.onrender.com/ia/asignar'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_padreToken',
            },
            body: jsonEncode(d),
          );
        } catch (_) {}
      }
    }
  });

  // Escribe en las SharedPreferences reales del dispositivo (no mock)
  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _hijoToken);
    await prefs.setString('user_id', _hijoId);
  });

  // ── 1. HU-01: Como padre, quiero registrarme con mi correo y contraseña ─────
  testWidgets('1. HU-01 — Padre crea cuenta: formulario visible y acepta datos',
      (tester) async {
    await tester.pumpWidget(_app(const RegistroScreen()));
    await tester.pump(const Duration(seconds: 1));

    final campos = find.byType(TextField);
    expect(campos, findsWidgets);

    await tester.enterText(campos.at(0), 'María González');
    await tester.enterText(campos.at(1), 'maria@gmail.com');
    await tester.enterText(campos.at(2), 'clave1234');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('María González'), findsOneWidget);
    expect(find.text('maria@gmail.com'), findsOneWidget);
  });

  // ── 2. HU-03: Como hijo, quiero iniciar sesión con mis credenciales ──────────
  testWidgets(
      '2. HU-03 — Hijo inicia sesión: campos de email y contraseña visibles',
      (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.pump(const Duration(seconds: 1));

    final campos = find.byType(TextField);
    expect(campos, findsWidgets);

    await tester.enterText(campos.at(0), '3ratoncitasbellas@gmail.com');
    await tester.enterText(campos.at(1), 'clave1234');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('3ratoncitasbellas@gmail.com'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  // ── 3. HU-02: Como padre, quiero crear un perfil para mi hijo ───────────────
  testWidgets('3. HU-02 — Padre registra un hijo: formulario completo',
      (tester) async {
    await tester.pumpWidget(_app(const AgregarHijoScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Agregar Hij@'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Catalina');
    await tester.enterText(campos.at(1), 'hijo.test.smoke@gmail.com');
    await tester.enterText(campos.at(2), 'clave1234');
    await tester.enterText(campos.at(3), '14');
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Femenino').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Media').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Curioso/a').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Música'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tecnología'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Deportes'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Catalina'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  // ── 4. HU-08: Como padre, generar desafíos para que el hijo no se quede sin misiones ──
  testWidgets('4. HU-08 — Padre gestiona desafíos del hijo',
      (tester) async {
    // Token del padre para que el API acepte la petición de gestión
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _padreToken);
    await prefs.setString('user_id', _hijoId);

    await tester.pumpWidget(_app(
      DesafiosHijoScreen(hijo: {'id': _hijoId, 'nombre': 'Catalina'}),
    ));
    await Future.delayed(const Duration(seconds: 8));
    await tester.pump();

    expect(find.text('Desafíos de Catalina'), findsOneWidget);
    expect(
      find.text('No hay desafíos asignados.\nGenera algunos con IA.')
              .evaluate()
              .isNotEmpty ||
          find.byType(ExpansionTile).evaluate().isNotEmpty,
      isTrue,
    );
    await Future.delayed(const Duration(seconds: 3));
  });

  // ── 5. HU-04: Como padre, seleccionar qué aplicaciones deseo bloquear ────────
  testWidgets('5. HU-04 — Padre configura protección del hijo', (tester) async {
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

      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('2 a 3 minutos'), findsOneWidget);
    }, () => mockVacio);
  });

  // ── 6. HU-09: Como padre, gestionar recompensas vinculadas a los desafíos ────
  testWidgets(
      '6. HU-09 — Padre gestiona recompensas: tienda con costos en puntos',
      (tester) async {
    await tester.pumpWidget(_app(const RecompensasScreen()));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Tienda de Recompensas'), findsOneWidget);
    expect(find.text('Elegir la película'), findsOneWidget);
    expect(find.text('150 MapachePoints'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  // ── 7. HU-07: Como hijo, ver los desafíos pendientes asignados por el padre ──
  testWidgets('7. HU-07 — Hijo ve sus desafíos pendientes', (tester) async {
    await tester.pumpWidget(_app(const MisDesafiosScreen()));
    await Future.delayed(const Duration(seconds: 8));
    await tester.pump();

    expect(find.text('Mis desafíos'), findsOneWidget);
    expect(
      find.text('¡No tienes misiones pendientes! 🦝').evaluate().isNotEmpty ||
          find.byType(ListView).evaluate().isNotEmpty,
      isTrue,
    );
    await Future.delayed(const Duration(seconds: 3));
  });

  // ── 8. HU-06: Como hijo, elegir mascota como recompensa ──────────────────────
  testWidgets('8. HU-06 — Hijo elige su mascota como recompensa',
      (tester) async {
    await tester.pumpWidget(_app(const SeleccionAvatarScreen()));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('¡Elige tu compañero!'), findsOneWidget);
    await Future.delayed(const Duration(seconds: 4));
  });

  // ── 9. HU-05: Como hijo, ver pantalla de bloqueo al abrir app restringida ────
  testWidgets('9. HU-05 — Hijo ve pantalla de bloqueo y no puede salir',
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

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.maybePop();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('App bloqueada'), findsOneWidget);
  });
}
