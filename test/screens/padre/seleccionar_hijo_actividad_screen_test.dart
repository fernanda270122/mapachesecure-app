import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/seleccionar_hijo_actividad_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: SeleccionarHijoActividadScreen()),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
    ApiService.testClient = MockClient((req) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  group('Pruebas para SeleccionarHijoActividadScreen', () {
    testWidgets(
      '1. Muestra "Actividad de Pantalla" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Actividad de Pantalla'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra mensaje vacío cuando no hay hijos registrados',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('No tienes hijos registrados'), findsOneWidget);
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
  });

  group('Pruebas con datos', () {
    const _hijoJson =
        '[{"id":"hijo1","nombre":"Ana","sexo":"femenino","edad":9}]';

    Future<void> cargar(WidgetTester tester, {String hijosJson = _hijoJson}) async {
      ApiService.testClient = MockClient((req) async => http.Response(hijosJson, 200));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
    }

    testWidgets('5. Muestra el nombre del hijo cuando hay datos', (tester) async {
      await cargar(tester);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('6. Muestra el texto de instruccion al cargar hijos', (tester) async {
      await cargar(tester);
      expect(find.text('Selecciona un hijo para revisar su uso de aplicaciones'), findsOneWidget);
    });

    testWidgets('7. Muestra el subtitulo Toca para ver el reporte de hoy', (tester) async {
      await cargar(tester);
      expect(find.text('Toca para ver el reporte de hoy'), findsOneWidget);
    });

    testWidgets('8. Muestra icono de analytics en la tarjeta del hijo', (tester) async {
      await cargar(tester);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('9. Muestra icono de flecha de navegacion en la tarjeta', (tester) async {
      await cargar(tester);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('10. Sin hijos muestra estado vacio', (tester) async {
      await cargar(tester, hijosJson: '[]');
      expect(find.text('No tienes hijos registrados'), findsOneWidget);
    });
  });
}
