import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/colores_screen.dart';
import 'package:mapachesecure_app/theme/app_paletas.dart';

Widget _wrap() => ChangeNotifierProvider(
  create: (_) => TemaProvider(),
  child: const MaterialApp(home: ColoresScreen()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para ColoresScreen', () {
    testWidgets('1. Muestra el título "Colores" en el AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Colores'), findsOneWidget);
    });

    testWidgets('2. Muestra el texto "Elige un tema de colores"', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Elige un tema de colores'), findsOneWidget);
    });

    testWidgets(
      '3. Muestra una opción por cada paleta disponible en AppPaletas',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        for (final nombre in AppPaletas.paletas.keys) {
          expect(find.text(nombre), findsOneWidget);
        }
      },
    );

    testWidgets('4. Botón "Aplicar tema" está visible', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Aplicar tema'), findsOneWidget);
    });

    testWidgets(
      '5. Tap en una paleta diferente cambia la selección (ícono check aparece)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        // Tomamos el segundo nombre de paleta para seleccionarlo
        final segundaPaleta = AppPaletas.paletas.keys.elementAt(1);
        await tester.tap(find.text(segundaPaleta));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets('6. Tap en "Aplicar tema" no lanza excepción', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar tema'));
      await tester.pumpAndSettle();
      // Si llegamos aquí sin excepción, el test pasa
    });

    testWidgets(
      '7. Tap en flecha de regreso ejecuta Navigator.pop y regresa a la pantalla anterior',
      (tester) async {
        // Envolver ColoresScreen dentro de una ruta para que Navigator.pop funcione
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => TemaProvider(),
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => TemaProvider(),
                        child: const ColoresScreen(),
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        // Regresamos a la pantalla inicial
        expect(find.text('Abrir'), findsOneWidget);
      },
    );
  });
}
