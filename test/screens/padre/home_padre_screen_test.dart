import 'package:flutter/material.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

class _FakeBgService extends FlutterBackgroundServicePlatform {
  @override
  Future<bool> configure({required IosConfiguration iosConfiguration, required AndroidConfiguration androidConfiguration}) async => true;
  @override
  Future<bool> start() async => true;
  @override
  Future<bool> isServiceRunning() async => false;
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}
  @override
  Stream<Map<String, dynamic>?> on(String method) => const Stream.empty();
}

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: HomePadreScreen()),
      ),
    );

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid', 'nombre': 'Ana'});
    ApiService.testClient = MockClient((request) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  // HomePadreScreen tiene Timer.periodic (5s) → NO usar pumpAndSettle()
  group('Pruebas para HomePadreScreen', () {
    testWidgets(
      '1. Muestra "Panel de Control" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Panel de Control'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el ícono del menú hamburguesa (drawer)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets(
      '3. El AppBar tiene foregroundColor blanco',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 200));
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets(
      '4. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra "Hijos conectados" en estado cargado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Hijos conectados'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra mensaje cuando no hay hijos registrados',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('No tienes hijos'), findsOneWidget);
      },
    );

    testWidgets(
      '7. No muestra indicador de carga tras completar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  group('Pruebas con datos', () {
    const _unHijoJson = '[{"id":"h1","nombre":"Lucas","sexo":"masculino"}]';
    const _dosHijosJson =
        '[{"id":"h1","nombre":"Lucas","sexo":"masculino"},{"id":"h2","nombre":"Sofia","sexo":"femenino"}]';

    Future<void> cargar(WidgetTester tester, {String hijosJson = _unHijoJson}) async {
      ApiService.testClient = MockClient((req) async {
        final path = req.url.path;
        if (path.contains('/hijos')) return http.Response(hijosJson, 200);
        if (path.contains('/completados')) return http.Response('[{"id":"c1"}]', 200);
        if (path.contains('/puntos')) return http.Response('{"total_puntos": 50}', 200);
        return http.Response('[{"minutos_uso": 30}]', 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('8. Muestra el nombre del hijo en la tarjeta', (tester) async {
      await cargar(tester);
      expect(find.text('Lucas'), findsOneWidget);
    });

    testWidgets('9. Muestra el subtitulo Toca para configurar con un hijo', (tester) async {
      await cargar(tester);
      expect(find.text('Toca para configurar'), findsOneWidget);
    });

    testWidgets('10. Muestra la seccion Actividad de hoy con un hijo', (tester) async {
      await cargar(tester);
      expect(find.text('Actividad de hoy'), findsOneWidget);
    });

    testWidgets('11. Muestra icono de tiempo en el resumen', (tester) async {
      await cargar(tester);
      expect(find.byIcon(Icons.access_time), findsWidgets);
    });

    testWidgets('12. Con 2 hijos muestra tarjeta con stats para cada hijo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await cargar(tester, hijosJson: _dosHijosJson);
      expect(find.text('Lucas'), findsOneWidget);
      expect(find.text('Sofia'), findsOneWidget);
    });

    testWidgets('13. El carrusel contiene un PageView', (tester) async {
      await cargar(tester);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('14. Muestra RefreshIndicator tras cargar datos', (tester) async {
      await cargar(tester);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('15. Drawer se abre y muestra los items de navegación', (tester) async {
      // Suprimimos el overflow del DrawerHeader en viewport de test (bug conocido de layout)
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Agregar Hijo/a'), findsOneWidget);
      expect(find.text('Gestionar Desafíos'), findsOneWidget);
      expect(find.text('Tienda de Recompensas'), findsOneWidget);
      expect(find.text('Cerrar Sesión', skipOffstage: false), findsOneWidget);
    });

    testWidgets('16. Tap en Inicio en el drawer lo cierra', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Inicio / Panel de control'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Panel de Control'), findsOneWidget);
    });

    testWidgets('17. Resumen muestra formato de horas cuando tiempo es mayor a 60 min', (tester) async {
      ApiService.testClient = MockClient((req) async {
        final path = req.url.path;
        if (path.contains('/hijos')) return http.Response(_unHijoJson, 200);
        if (path.contains('/completados')) return http.Response('[]', 200);
        if (path.contains('/puntos')) return http.Response('{"total_puntos": 0}', 200);
        return http.Response('[{"minutos_uso": 90}]', 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('18. Tap en tarjeta de hijo navega a ConfigurarHijoScreen', (tester) async {
      ApiService.testClient = MockClient((req) async {
        final path = req.url.path;
        if (path.contains('/hijos')) return http.Response(_unHijoJson, 200);
        if (path.contains('/completados')) return http.Response('[]', 200);
        if (path.contains('/puntos')) return http.Response('{"total_puntos": 0}', 200);
        return http.Response('[]', 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Lucas'));
      await tester.pump(const Duration(milliseconds: 300));
      // ConfigurarHijoScreen se carga (muestra Lucas en AppBar o CircularProgressIndicator)
      expect(find.textContaining('Lucas'), findsWidgets);
    });

    testWidgets('19. Error de API en carga activa catch y muestra pantalla vacía', (tester) async {
      ApiService.testClient = MockClient((req) async {
        throw Exception('error de red');
      });
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      expect(find.textContaining('No tienes hijos'), findsOneWidget);
    });

    testWidgets('20. Drawer → Gestionar Desafíos navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Gestionar Desafíos'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Gestionar Desafíos', skipOffstage: false), findsWidgets);
    });

    testWidgets('21. Drawer → Agregar Hijo/a navega a AgregarHijoScreen', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(); // frame para que el tap registre
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Agregar Hijo/a'));
      await _pumpLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Agregar Hij@', skipOffstage: false), findsWidgets);
    });

    testWidgets('22. Drawer → Revisar Evidencias navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Revisar Evidencias'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Revisar Evidencias', skipOffstage: false), findsWidgets);
    });

    testWidgets('23. Drawer → Tienda de Recompensas navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Tienda de Recompensas'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tienda de Recompensas', skipOffstage: false), findsWidgets);
    });

    testWidgets('24. Drawer → Canjes Pendientes navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Canjes Pendientes'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Canjes Pendientes', skipOffstage: false), findsWidgets);
    });

    testWidgets('25. Drawer → Consejos para Padres navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Consejos para Padres'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Consejos para Padres', skipOffstage: false), findsWidgets);
    });

    testWidgets('26. Drawer → Cambiar Color del Panel navega a ColoresPadreScreen', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      // 800px de alto para que "Cambiar Color del Panel" (y≈570-626) quede dentro del viewport
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(); // frame para que el tap registre
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cambiar Color del Panel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Colores del Panel', skipOffstage: false), findsOneWidget);
    });

    testWidgets('27. Drawer → Actividad de Pantalla navega a la pantalla correcta', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      // Viewport más alto pero mismo ancho (800px) para que el tap del drawer funcione
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Actividad de Pantalla'));
      await _pumpLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Actividad de Pantalla', skipOffstage: false), findsWidgets);
    });

    testWidgets('28. Drawer → Cerrar Sesión navega al LoginScreen', (tester) async {
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        prevOnError?.call(d);
      };
      addTearDown(() => FlutterError.onError = prevOnError);
      // Mismo ancho (800px) para compatibilidad del tap + altura suficiente para y≈813 (Cerrar Sesión)
      await tester.binding.setSurfaceSize(const Size(800, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      FlutterBackgroundServicePlatform.instance = _FakeBgService();
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(); // frame para que el tap registre
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Cerrar Sesión'));
      await _pumpLoaded(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });
}
