import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/screens/hijo/app_bloqueada_screen.dart';

Widget _wrap(String nombreApp) => MaterialApp(
      routes: {
        '/home-hijo': (_) => const Scaffold(body: Text('Pantalla Hijo')),
      },
      home: AppBloqueadaScreen(nombreAppIntentada: nombreApp),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para AppBloqueadaScreen', () {
    testWidgets('1. Muestra el titulo de alerta ALTO AHI', (tester) async {
      await tester.pumpWidget(_wrap('YouTube'));
      await tester.pumpAndSettle();
      expect(find.text('¡ALTO AHÍ!'), findsOneWidget);
    });

    testWidgets('2. Muestra el nombre de la app bloqueada en el mensaje', (tester) async {
      await tester.pumpWidget(_wrap('TikTok'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('TikTok'),
        findsOneWidget,
      );
    });

    testWidgets('3. Muestra el icono de candado de persona', (tester) async {
      await tester.pumpWidget(_wrap('YouTube'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);
    });

    testWidgets('4. Muestra el boton VOLVER A RACCU', (tester) async {
      await tester.pumpWidget(_wrap('YouTube'));
      await tester.pumpAndSettle();
      expect(find.text('VOLVER A RACCU'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('5. El fondo del Scaffold es rojo de advertencia', (tester) async {
      await tester.pumpWidget(_wrap('YouTube'));
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFB71C1C));
    });

    testWidgets('6. Tap en VOLVER A RACCU navega a la pantalla del hijo', (tester) async {
      await tester.pumpWidget(_wrap('YouTube'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VOLVER A RACCU'));
      await tester.pumpAndSettle();
      expect(find.text('Pantalla Hijo'), findsOneWidget);
    });
  });
}
