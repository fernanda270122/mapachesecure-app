import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/actividad_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

const _hijoTest = {'id': 'hijo-uid-123', 'nombre': 'Lucas'};

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(
          home: ActividadHijoScreen(hijo: _hijoTest),
        ),
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

  group('Pruebas para ActividadHijoScreen', () {
    testWidgets(
      '1. Muestra el nombre del hijo en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.textContaining('Lucas'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra indicador de carga en estado inicial',
      (tester) async {
        await tester.pumpWidget(_wrap());
        // Check loading state immediately, before async completes
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
      '5. Muestra "Resumen de Hoy" tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Resumen de Hoy'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra "Tiempo por Aplicación" en el estado cargado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Tiempo por Aplicaci'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Muestra mensaje cuando no hay registros de actividad',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('No hay registros'), findsOneWidget);
      },
    );
  });
}
