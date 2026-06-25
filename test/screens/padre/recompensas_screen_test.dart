import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/recompensas_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
  create: (_) => TemaPadreProvider(),
  child: const MaterialApp(home: RecompensasScreen()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para RecompensasScreen', () {
    testWidgets('1. Muestra el titulo Tienda de Recompensas en el AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Tienda de Recompensas'), findsOneWidget);
    });

    testWidgets('2. Muestra la lista con 8 recompensas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsNWidgets(8));
    });

    testWidgets('3. Muestra la primera recompensa Elegir la pelicula', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Elegir la película'), findsOneWidget);
    });

    testWidgets('4. Muestra los puntos de la primera recompensa', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('150 MapachePoints'), findsOneWidget);
    });

    testWidgets('5. Todos los switches inician en estado inactivo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final tile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile).first,
      );
      expect(tile.value, false);
    });

    testWidgets(
      '6. Activar el switch de la primera recompensa cambia su estado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch).first);
        await tester.pump();
        final tile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile).first,
        );
        expect(tile.value, true);
      },
    );

    testWidgets('7. Muestra otras recompensas de la lista', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Noche de pizza', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Salida al parque', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('30 min extra de juegos', skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
