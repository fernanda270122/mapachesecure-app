import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
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

    testWidgets('2. Fondo de la pantalla es negro', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SeleccionAvatarScreen()));
      await tester.pump(Duration.zero);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('3. Muestra el texto "¡Elige tu compañero!"', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SeleccionAvatarScreen()));
      await tester.pump(Duration.zero);
      expect(find.text('¡Elige tu compañero!'), findsOneWidget);
    });

    testWidgets('4. Muestra flechas de navegación izquierda y derecha', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SeleccionAvatarScreen()));
      await tester.pump(Duration.zero);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('5. Tap en flecha derecha cambia al siguiente avatar (_irA)', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SeleccionAvatarScreen()));
      await tester.pump();
      expect(find.text('Mago'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.text('Dormilón'), findsOneWidget);
    });

    testWidgets('6. Tap en flecha izquierda regresa al avatar anterior', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SeleccionAvatarScreen()));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.text('Dormilón'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(find.text('Mago'), findsOneWidget);
    });

    testWidgets(
      '7. Botón elegir está deshabilitado mientras el video no ha cargado',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump();
        final boton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(boton.onPressed, isNull);
      },
    );

    testWidgets(
      '8. Navegar hasta el último avatar deshabilita la flecha derecha',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump();
        // Navegar hasta el último avatar
        for (int i = 0; i < AvatarTypes.todos.length - 1; i++) {
          await tester.tap(find.byIcon(Icons.chevron_right));
          await tester.pump();
        }
        expect(find.text('Princesa'), findsOneWidget);
        // Tap en flecha derecha cuando está en el último no cambia el avatar
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
        expect(find.text('Princesa'), findsOneWidget);
      },
    );

    testWidgets(
      '9. El botón muestra el nombre del avatar y cambia con la navegación',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: SeleccionAvatarScreen()),
        );
        await tester.pump();
        // El botón muestra el nombre del avatar actual en mayúsculas
        expect(find.text('¡ELEGIR A MAGO!'), findsOneWidget);
        // Tras navegar al siguiente el texto del botón cambia
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();
        expect(find.text('¡ELEGIR A DORMILÓN!'), findsOneWidget);
      },
    );

    testWidgets('10. Navegar fuera de la pantalla ejecuta dispose sin error', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => const SeleccionAvatarScreen(),
                ),
              ),
              child: const Text('Ir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ir'));
      await tester.pump(); // procesar el tap
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SeleccionAvatarScreen), findsOneWidget);
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.pop();
      await tester.pump(); // iniciar animación de retorno
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SeleccionAvatarScreen), findsNothing);
    });
  });
}
