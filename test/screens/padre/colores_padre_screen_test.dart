import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/colores_padre_screen.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaPadreProvider(),
      child: const MaterialApp(home: ColoresPadreScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para ColoresPadreScreen', () {
    testWidgets(
      '1. Muestra "Colores del Panel" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Colores del Panel'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el título "Configuración Visual (Padre)"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Configuración Visual (Padre)'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra una opción por cada paleta disponible en AppPaletasPadre',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        for (final nombre in AppPaletasPadre.paletas.keys) {
          expect(find.text(nombre), findsOneWidget);
        }
      },
    );

    testWidgets(
      '4. Botón "Aplicar colores de Padre" está visible',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Aplicar colores de Padre'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Tap en una paleta diferente muestra ícono de check',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        final segunda = AppPaletasPadre.paletas.keys.elementAt(1);
        await tester.tap(find.text(segunda));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );
  });
}
