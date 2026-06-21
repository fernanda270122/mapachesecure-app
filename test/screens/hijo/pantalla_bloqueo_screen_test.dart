import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para PantallaBloqueoScreen', () {
    testWidgets('1. Muestra "App bloqueada" en el cuerpo de la pantalla', (tester) async {
      // Instanciación sin const: el constructor se ejecuta en tiempo de ejecución y LCOV lo contabiliza (L8)
      final horaInicio = '22:00';
      final horaFin = '07:00';
      await tester.pumpWidget(MaterialApp(
        home: PantallaBloqueoScreen(horaInicio: horaInicio, horaFin: horaFin),
      ));
      await tester.pumpAndSettle();
      expect(find.text('App bloqueada'), findsOneWidget);
    });

    testWidgets('2. Muestra el horario de bloqueo correcto', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PantallaBloqueoScreen(horaInicio: '20:00', horaFin: '08:00'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('20:00 - 08:00'), findsOneWidget);
    });

    testWidgets('3. Muestra el ícono de candado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PantallaBloqueoScreen(horaInicio: '21:00', horaFin: '06:00'),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
