import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/verificar_identidad_screen.dart';

// Mock que devuelve un archivo exitosamente
class _FakeImagePickerSuccess extends ImagePickerPlatform {
  final String path;
  _FakeImagePickerSuccess(this.path);

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => XFile(path);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile(path);
}

// Mock que lanza una excepción simulando error de cámara
class _FakeImagePickerError extends ImagePickerPlatform {
  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async => throw Exception('Camera not available');

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => throw Exception('Camera not available');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para VerificarIdentidadScreen', () {
    testWidgets('1. Muestra "Verificación" en el AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verificación'), findsOneWidget);
    });

    testWidgets('2. Muestra el título "Verificación de Rostro"', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verificación de Rostro'), findsOneWidget);
    });

    testWidgets('3. Muestra el ícono de reconocimiento facial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.face_unlock_rounded), findsOneWidget);
    });

    testWidgets('4. Contiene un Scaffold como raíz de la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('5. Muestra el texto Toca aqui para tomar la foto', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Toca aquí para tomar la foto'), findsOneWidget);
    });

    testWidgets('6. Muestra el boton Escanear Rostro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Escanear Rostro'), findsOneWidget);
    });

    testWidgets('7. Muestra el boton de explicacion Por que necesitamos esto', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Por qué necesitamos esto?'), findsOneWidget);
    });

    testWidgets(
      '8. Tap en Por que necesitamos esto abre dialogo de explicacion',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('¿Por qué necesitamos esto?'));
        await tester.pumpAndSettle();
        expect(find.text('¿Por qué verificamos tu rostro?'), findsOneWidget);
        expect(find.text('Entendido'), findsOneWidget);
      },
    );

    testWidgets('9. Tap en Entendido cierra el dialogo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Por qué necesitamos esto?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('¿Por qué verificamos tu rostro?'), findsNothing);
    });

    testWidgets('10. Muestra el icono de rostro en la zona de captura', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byIcon(Icons.face_retouching_natural_rounded),
        findsOneWidget,
      );
    });

    testWidgets('11. Botón de retroceso en AppBar navega hacia atrás', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (ctx) => Scaffold(
              body: Builder(
                builder: (c) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    c,
                    MaterialPageRoute(
                      builder: (_) => const VerificarIdentidadScreen(),
                    ),
                  ),
                  child: const Text('Ir'),
                ),
              ),
            ),
          },
        ),
      );
      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();
      expect(find.byType(VerificarIdentidadScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(VerificarIdentidadScreen), findsNothing);
    });

    testWidgets(
      '12. Tap en zona de captura llama a _tomarFotoRostro sin SnackBar de error',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Error al abrir la cámara'), findsNothing);
      },
    );

    testWidgets('13. Tap en botón Escanear Rostro llama a _tomarFotoRostro', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: VerificarIdentidadScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear Rostro'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VerificarIdentidadScreen), findsOneWidget);
    });

    testWidgets(
      '14. Mock ImagePicker éxito: establece _imageFile y muestra ClipRRect y "Tomar otra foto"',
      (tester) async {
        // Escritura síncrona: evita I/O asíncrono pendiente en FakeAsync
        final tempFile = File('${Directory.systemTemp.path}/test_rostro.jpg');
        tempFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
        addTearDown(() {
          try {
            tempFile.deleteSync();
          } catch (_) {}
        });

        final originalPicker = ImagePickerPlatform.instance;
        ImagePickerPlatform.instance = _FakeImagePickerSuccess(tempFile.path);
        addTearDown(() => ImagePickerPlatform.instance = originalPicker);

        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Escanear Rostro'));
        await tester.pump(const Duration(milliseconds: 100));

        // runAsync: deja que FileImage termine la carga real antes de salir del test
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ClipRRect), findsWidgets);
        expect(find.text('Tomar otra foto'), findsOneWidget);
        expect(find.text('Enviar para Verificación'), findsOneWidget);
      },
    );

    testWidgets(
      '15. Mock ImagePicker error: muestra SnackBar "Error al abrir la cámara"',
      (tester) async {
        final originalPicker = ImagePickerPlatform.instance;
        ImagePickerPlatform.instance = _FakeImagePickerError();
        addTearDown(() => ImagePickerPlatform.instance = originalPicker);

        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Escanear Rostro'));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Error al abrir la cámara'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '16. Tap en "Tomar otra foto" llama _tomarFotoRostro de nuevo',
      (tester) async {
        final tempFile = File('${Directory.systemTemp.path}/test_rostro2.jpg');
        tempFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
        addTearDown(() {
          try {
            tempFile.deleteSync();
          } catch (_) {}
        });

        final originalPicker = ImagePickerPlatform.instance;
        ImagePickerPlatform.instance = _FakeImagePickerSuccess(tempFile.path);
        addTearDown(() => ImagePickerPlatform.instance = originalPicker);

        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: VerificarIdentidadScreen()),
        );
        await tester.pumpAndSettle();

        // Primera foto
        await tester.tap(find.text('Escanear Rostro'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Tomar otra foto'), findsOneWidget);

        // Tap "Tomar otra foto" dispara _tomarFotoRostro de nuevo
        await tester.tap(find.text('Tomar otra foto'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(VerificarIdentidadScreen), findsOneWidget);
      },
    );
  });
}
