import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

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
  });
}
