import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/tienda_recompensa_hijo_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: TiendaRecompensasHijoScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'test-uid'});
  });

  group('Pruebas para TiendaRecompensasHijoScreen', () {
    testWidgets(
      '1. Muestra "Tienda de Premios" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Tienda de Premios'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra "Tienes:" en el encabezado de puntos tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Tienes:'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra "0" como puntos iniciales cuando la API falla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('0'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra ícono de estrellas en el encabezado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.stars), findsOneWidget);
      },
    );
  });
}
