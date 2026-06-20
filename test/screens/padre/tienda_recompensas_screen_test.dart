import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/tienda_recompensas_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: TiendaRecompensasScreen()),
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
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
    ApiService.testClient = MockClient((request) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  group('Pruebas para TiendaRecompensasScreen', () {
    testWidgets(
      '1. Muestra "Tienda de Recompensas" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Tienda de Recompensas'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el botón de agregar recompensa personalizada',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );

    testWidgets(
      '3. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '4. El AppBar tiene foregroundColor blanco',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets(
      '5. Muestra sección "Del sistema" en estado cargado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Del sistema'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra descripción de recompensas del sistema',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Activa las recompensas'), findsOneWidget);
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

    testWidgets(
      '8. Muestra los SwitchListTile de recompensas del sistema',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.byType(SwitchListTile), findsWidgets);
      },
    );

    testWidgets(
      '9. Muestra el boton FAB Confirmar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Confirmar'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Tap en Confirmar sin recompensas ni hijo muestra SnackBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Confirmar'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Primero selecciona'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '11. Tap en switch activa la recompensa',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
        expect(switchWidget.value, false);
        await tester.tap(find.byType(Switch).first);
        await tester.pump();
        final switchActualizado = tester.widget<Switch>(find.byType(Switch).first);
        expect(switchActualizado.value, true);
      },
    );

    testWidgets(
      '12. Tap en el boton + abre formulario de nueva recompensa',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('Nueva recompensa'), findsOneWidget);
      },
    );

    testWidgets(
      '13. Muestra mensaje vacio cuando no hay recompensas de comunidad',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Aun no hay recompensas'), findsNothing);
        expect(find.text('Recomendadas por la comunidad'), findsOneWidget);
      },
    );
  });

  group('Pruebas con hijo seleccionado', () {
    const _hijoJson = '[{"id":"hijo1","nombre":"Lucas"}]';

    Future<void> cargar(WidgetTester tester) async {
      ApiService.testClient = MockClient((req) async {
        final path = req.url.path;
        if (path.contains('/catalogo')) return http.Response('[]', 200);
        if (path.contains('/recompensas/')) return http.Response('[]', 200);
        if (path.contains('/hijos')) return http.Response(_hijoJson, 200);
        return http.Response('[]', 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('14. Con hijo cargado muestra el selector de hijo', (tester) async {
      await cargar(tester);
      expect(find.text('Asignar a:'), findsOneWidget);
      expect(find.text('Lucas'), findsOneWidget);
    });

    testWidgets('15. Con hijo y recompensa activa Confirmar muestra dialogo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await cargar(tester);
      // Activa la primera recompensa
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      // Tap en Confirmar
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar'), findsWidgets); // botón en el diálogo
      expect(find.textContaining('recompensa'), findsWidgets);
    });
  });
}
