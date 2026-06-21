import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:mapachesecure_app/screens/hijo/video_evolucion_screen.dart';

// Plataforma falsa que simula inicialización exitosa del video
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => 1;

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox();

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.fromIterable([
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(640, 480),
          duration: const Duration(seconds: 2),
          rotationCorrection: 0,
        ),
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para VideoEvolucionScreen (sin plataforma real)', () {
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(VideoEvolucionScreen), findsOneWidget);
        final NavigatorState nav = tester.state(find.byType(Navigator));
        nav.pop();
        await tester.pump();
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
        expect(find.text('Mensaje de prueba'), findsOneWidget);
      },
    );
  });

  group('Pruebas con FakeVideoPlayerPlatform (video inicializa correctamente)', () {
    setUp(() {
      // Reemplazamos la plataforma nativa con una falsa para que initialize() tenga éxito
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
    });

    testWidgets(
      '7. Constructor no-const crea la pantalla correctamente (cubre L8)',
      (tester) async {
        final path = 'assets/videos/mago_evoluciona.mp4';
        await tester.pumpWidget(MaterialApp(
          home: VideoEvolucionScreen(videoPath: path),
        ));
        await tester.pump(Duration.zero);
        expect(find.byType(VideoEvolucionScreen), findsOneWidget);
      },
    );

    testWidgets(
      '8. Con fake platform el video inicializa y muestra FittedBox (cubre L37-38, L55, L72-77)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: VideoEvolucionScreen(
              videoPath: 'assets/videos/mago_evoluciona.mp4',
            ),
          ),
        );
        // Pump para procesar initState + el Future de _initVideo
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        // Después de inicializar, _inicializado=true → FittedBox visible en lugar del spinner
        expect(find.byType(FittedBox), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
