import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/screens/hijo/seleccion_avatar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para SeleccionAvatarScreen', () {
    testWidgets(
      '1. Muestra CircularProgressIndicator mientras el video carga',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump(Duration.zero);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      '2. Fondo de la pantalla es negro',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump(Duration.zero);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
      },
    );

    testWidgets(
      '3. Muestra el texto "¡Elige tu compañero!"',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump(Duration.zero);
        expect(find.text('¡Elige tu compañero!'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra flechas de navegación izquierda y derecha',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump(Duration.zero);
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );
  });
}
