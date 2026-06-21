import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/revisar_evidencias_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaPadreProvider(),
      child: const MaterialApp(home: RevisarEvidenciasScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
    ApiService.testClient = MockClient((request) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  const _evidenciaJson =
      '[{"id":"ev1","titulo":"Leer 30 minutos","hijo_nombre":"Lucas","url_evidencia":null}]';

  Future<void> cargar(
    WidgetTester tester, {
    String evidenciasJson = _evidenciaJson,
  }) async {
    ApiService.testClient = MockClient((req) async {
      if (req.method == 'PUT') return http.Response('{"ok": true}', 200);
      return http.Response(evidenciasJson, 200);
    });
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
  }

  group('Pruebas para RevisarEvidenciasScreen', () {
    testWidgets(
      '1. Muestra "Revisar Evidencias" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Revisar Evidencias'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra estado vacío cuando no hay evidencias pendientes',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('No hay evidencias pendientes por ahora 👏'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '4. El AppBar usa el color del tema padre',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );
  });

  group('Pruebas con datos', () {
    testWidgets('5. Muestra el titulo del desafio en la tarjeta', (tester) async {
      await cargar(tester);
      expect(find.text('Leer 30 minutos'), findsOneWidget);
    });

    testWidgets('6. Muestra el nombre del hijo en la tarjeta', (tester) async {
      await cargar(tester);
      expect(find.text('Hijo: Lucas'), findsOneWidget);
    });

    testWidgets('7. Muestra los botones Rechazar y Aprobar', (tester) async {
      await cargar(tester);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Aprobar'), findsOneWidget);
    });

    testWidgets('8. Muestra icono de history_edu en la tarjeta', (tester) async {
      await cargar(tester);
      expect(find.byIcon(Icons.history_edu), findsOneWidget);
    });

    testWidgets('9. Tap en Rechazar muestra dialogo de confirmacion', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Sí, Rechazar'), findsOneWidget);
    });

    testWidgets('10. Tap en Aprobar muestra dialogo de confirmacion', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Sí, Aprobar'), findsOneWidget);
    });

    testWidgets('11. Cancelar en el dialogo cierra sin ejecutar accion', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Sí, Rechazar'), findsNothing);
    });

    testWidgets('12. Confirmar Aprobar muestra snackbar de exito', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, Aprobar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('aprobado'), findsOneWidget);
      // Avanza el tiempo para cerrar el SnackBar y evitar timers pendientes
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      '13. API retorna 500 en _fetchEvidencias muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'GET') {
            return http.Response('{"detail":"Error del servidor"}', 500);
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.textContaining('Error:'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '14. PUT falla en _procesarEvidencia muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'PUT') {
            return http.Response('{"detail":"Error al validar"}', 500);
          }
          return http.Response(_evidenciaJson, 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aprobar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sí, Aprobar'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Error:'), findsOneWidget);
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets(
      '15. Muestra Image.network cuando url_evidencia no es null',
      (tester) async {
        // Silencia el error de carga de imagen de red (esperado en tests)
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.library == 'image resource service') return;
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        const jsonConFoto =
            '[{"id":"ev2","titulo":"Reto imagen","hijo_nombre":"Maria","url_evidencia":"https://example.com/foto.jpg"}]';
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'PUT') return http.Response('{"ok":true}', 200);
          return http.Response(jsonConFoto, 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Image), findsOneWidget);
      },
    );
  });
}
