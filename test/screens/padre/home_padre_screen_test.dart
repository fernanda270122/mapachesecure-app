import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaPadreProvider(),
      child: const MaterialApp(home: HomePadreScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid', 'nombre': 'Ana'});
  });

  // HomePadreScreen tiene Timer.periodic → NO usar pumpAndSettle()
  // Se usa pump(Duration) para avanzar el reloj sin disparar el timer de 5s

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
  });
}
