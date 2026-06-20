import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaPadreProvider(),
      child: const MaterialApp(home: HomePadreScreen()),
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
}
