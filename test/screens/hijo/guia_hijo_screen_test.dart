import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/guia_hijo_screen.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: GuiaHijoScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para GuiaHijoScreen', () {
    testWidgets(
      '1. Muestra "Guía de la app" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Guía de la app'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra sección "¡Bienvenido a Raccu!"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('¡Bienvenido a Raccu!'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra sección sobre los desafíos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('¿Cómo funcionan los desafíos?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4. Muestra sección sobre los puntos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('¿Para qué sirven los puntos?'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Al hacer scroll muestra sección "Tu mascota Raccu"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Tu mascota Raccu'),
          300.0,
        );
        expect(find.text('Tu mascota Raccu'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Al hacer scroll muestra sección sobre apps bloqueadas',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('¿Por qué están bloqueadas mis apps?'),
          300.0,
        );
        expect(
          find.text('¿Por qué están bloqueadas mis apps?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Muestra al menos 3 tarjetas de sección visibles en el viewport',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byType(Card), findsAtLeastNWidgets(3));
      },
    );
  });
}
