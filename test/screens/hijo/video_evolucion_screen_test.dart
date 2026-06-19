import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/screens/hijo/video_evolucion_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para VideoEvolucionScreen', () {
    testWidgets(
      '1. Mientras el video inicializa muestra CircularProgressIndicator',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
            ),
          ),
        );
        // No esperamos settle — el video no puede inicializarse en tests
        await tester.pump(Duration.zero);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      '2. Widget usa fondo negro',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
            ),
          ),
        );
        await tester.pump(Duration.zero);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
      },
    );

    testWidgets(
      '3. Widget muestra el mensaje pasado como parámetro en el árbol',
      (tester) async {
        const mensajeEsperado = '¡Tu mapache ha evolucionado!';
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
              mensaje: mensajeEsperado,
            ),
          ),
        );
        await tester.pump(Duration.zero);
        expect(find.text(mensajeEsperado), findsOneWidget);
      },
    );

    testWidgets(
      '4. Sin parámetro mensaje usa el texto por defecto',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
            ),
          ),
        );
        await tester.pump(Duration.zero);
        expect(
          find.textContaining('¡Surge ahora y obedece mi llamada!'),
          findsOneWidget,
        );
      },
    );
  });
}
