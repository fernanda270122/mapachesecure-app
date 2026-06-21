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

    testWidgets(
      '5. Dispose se llama sin crash al navegar fuera de la pantalla',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const VideoEvolucionScreen(
                      videoPath: 'assets/videos/mago_evoluciona.mp4',
                    ),
                  ),
                ),
                child: const Text('Ir'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ir'));
        await tester.pump(); // procesar tap
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(VideoEvolucionScreen), findsOneWidget);
        final NavigatorState nav = tester.state(find.byType(Navigator));
        nav.pop();
        await tester.pump(); // iniciar animación de retorno
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(VideoEvolucionScreen), findsNothing);
      },
    );

    testWidgets(
      '6. AnimatedOpacity está presente con opacidad 0 cuando el mensaje no se muestra',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
              mensaje: 'Mensaje de prueba',
            ),
          ),
        );
        await tester.pump(Duration.zero);
        final animatedOpacity = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(animatedOpacity.opacity, 0.0);
        // El mensaje está en el árbol pero invisible
        expect(find.text('Mensaje de prueba'), findsOneWidget);
      },
    );
  });
}
