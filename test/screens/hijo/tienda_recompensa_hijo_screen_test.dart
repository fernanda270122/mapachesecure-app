import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/tienda_recompensa_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: TiendaRecompensasHijoScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'test-uid'});
    ApiService.testClient = MockClient((request) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  group('Pruebas para TiendaRecompensasHijoScreen', () {
    testWidgets(
      '1. Muestra "Tienda de Premios" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Tienda de Premios'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra "Tienes:" en el encabezado de puntos tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Tienes:'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra "0" como puntos iniciales cuando la API falla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('0'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra ícono de estrellas en el encabezado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.stars), findsOneWidget);
      },
    );
  });

  group('Pruebas con datos', () {
    void stubConRecompensa({int puntos = 100, bool pendiente = false}) {
      ApiService.testClient = MockClient((req) async {
        if (req.method == 'POST') return http.Response('{"ok": true}', 200);
        if (req.url.path.contains('/recompensas/')) {
          return http.Response(
            '[{"id":"1","titulo":"Videojuego","descripcion":"Jugar 1h","costo_puntos":50}]',
            200,
          );
        }
        if (req.url.path.contains('/desafios/puntos')) {
          return http.Response('{"total_puntos": $puntos}', 200);
        }
        if (req.url.path.contains('/canjes/tiene-pendiente')) {
          return http.Response('{"tiene_pendiente": $pendiente}', 200);
        }
        return http.Response('{}', 200);
      });
    }

    Future<void> cargar(WidgetTester tester, {int puntos = 100, bool pendiente = false}) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      stubConRecompensa(puntos: puntos, pendiente: pendiente);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
    }

    testWidgets('5. Muestra recompensa con botón CANJEAR cuando tiene puntos suficientes', (tester) async {
      await cargar(tester, puntos: 100);
      expect(find.text('CANJEAR', skipOffstage: false), findsOneWidget);
      expect(find.text('50 MapachePoints', skipOffstage: false), findsOneWidget);
    });

    testWidgets('6. Muestra EN ESPERA cuando hay canje pendiente', (tester) async {
      await cargar(tester, puntos: 100, pendiente: true);
      expect(find.text('EN ESPERA', skipOffstage: false), findsOneWidget);
    });

    testWidgets('7. Botón deshabilitado cuando no tiene puntos suficientes', (tester) async {
      await cargar(tester, puntos: 10);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'CANJEAR', skipOffstage: false),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('8. Tap en CANJEAR muestra diálogo de confirmación', (tester) async {
      await cargar(tester, puntos: 100);
      await tester.tap(find.text('CANJEAR', skipOffstage: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('¿Canjear'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('¡SÍ, CANJEAR!'), findsOneWidget);
    });

    testWidgets('9. Cancelar en diálogo lo cierra sin canjear', (tester) async {
      await cargar(tester, puntos: 100);
      await tester.tap(find.text('CANJEAR', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('¿Canjear'), findsNothing);
    });

    testWidgets('10. Confirmar canje muestra diálogo de éxito', (tester) async {
      await cargar(tester, puntos: 100);
      await tester.tap(find.text('CANJEAR', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¡SÍ, CANJEAR!'));
      await tester.pumpAndSettle();
      expect(find.text('¡Solicitud enviada!'), findsOneWidget);
      expect(find.text('¡Genial!'), findsOneWidget);
    });

    testWidgets('11. Cerrar diálogo de éxito con ¡Genial!', (tester) async {
      await cargar(tester, puntos: 100);
      await tester.tap(find.text('CANJEAR', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¡SÍ, CANJEAR!'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¡Genial!'));
      await tester.pumpAndSettle();
      expect(find.text('¡Solicitud enviada!'), findsNothing);
    });
  });
}
