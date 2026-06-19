import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: HomeHijoScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 'hijo-uid',
      'nombre': 'Lucas',
      'tipo_avatar': 'mago',
    });
  });

  // HomeHijoScreen tiene AnimationController.repeat() → NO usar pumpAndSettle()
  group('Pruebas para HomeHijoScreen', () {
    testWidgets(
      '1. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el saludo al usuario tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.textContaining('¡Hola,'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra el ícono de menú hamburguesa (drawer)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byIcon(Icons.menu), findsOneWidget);
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
}
