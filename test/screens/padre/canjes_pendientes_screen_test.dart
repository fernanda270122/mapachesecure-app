import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/canjes_pendientes_screen.dart';

Widget _wrap() => ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  builder: (_, __) => ChangeNotifierProvider(
    create: (_) => TemaPadreProvider(),
    child: const MaterialApp(home: CanjesPendientesScreen()),
  ),
);

const _canjesMasculino = '''[{
  "id": "canje-1",
  "recompensas": {"nombre": "Juguete", "puntos_requeridos": 100},
  "usuarios": {"nombre": "Lucas", "sexo": "masculino"}
}]''';

const _canjesFemenino = '''[{
  "id": "canje-2",
  "recompensas": {"nombre": "Libro", "puntos_requeridos": 50},
  "usuarios": {"nombre": "Sofia", "sexo": "femenino"}
}]''';

const _canjesOtro = '''[{
  "id": "canje-3",
  "recompensas": {"nombre": "Sticker", "puntos_requeridos": 20},
  "usuarios": {"nombre": "Alex", "sexo": null}
}]''';

Future<void> cargar(
  WidgetTester tester, {
  String json = _canjesMasculino,
  bool postOk = true,
}) async {
  CanjesPendientesScreen.testClient = MockClient((req) async {
    if (req.method == 'POST') {
      return postOk
          ? http.Response('{"ok":true}', 200)
          : http.Response('{"error":"fallo"}', 500);
    }
    return http.Response(json, 200);
  });
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
    CanjesPendientesScreen.testClient = null;
  });

  tearDown(() {
    CanjesPendientesScreen.testClient = null;
  });

  group('Pruebas para CanjesPendientesScreen', () {
    testWidgets('1. Muestra "Canjes Pendientes" en el AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Canjes Pendientes'), findsOneWidget);
    });

    testWidgets('2. Muestra mensaje de lista vacía cuando no hay canjes', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('No hay canjes esperando aprobación'), findsOneWidget);
    });

    testWidgets('3. Contiene un Scaffold como raíz de la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('4. Contiene SafeArea en el cuerpo', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
    });
  });

  group('Pruebas con datos', () {
    testWidgets('5. Lista de canjes muestra la recompensa y los puntos', (
      tester,
    ) async {
      await cargar(tester);
      expect(find.textContaining('Juguete'), findsOneWidget);
      expect(find.textContaining('100 pts'), findsOneWidget);
    });

    testWidgets('6. _genero con sexo masculino muestra "Hijo: Lucas"', (
      tester,
    ) async {
      await cargar(tester);
      expect(find.text('Hijo: Lucas'), findsOneWidget);
    });

    testWidgets('7. _genero con sexo femenino muestra "Hija: Sofia"', (
      tester,
    ) async {
      await cargar(tester, json: _canjesFemenino);
      expect(find.text('Hija: Sofia'), findsOneWidget);
    });

    testWidgets('8. _genero con sexo null muestra "Menor: Alex"', (
      tester,
    ) async {
      await cargar(tester, json: _canjesOtro);
      expect(find.text('Menor: Alex'), findsOneWidget);
    });

    testWidgets('9. Muestra ícono de tarjeta de regalo en la lista', (
      tester,
    ) async {
      await cargar(tester);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    });

    testWidgets(
      '10. Tap en aprobar llama _accion y ejecuta el flujo de éxito',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var postCalled = false;
        CanjesPendientesScreen.testClient = MockClient((req) async {
          if (req.method == 'POST') {
            postCalled = true;
            return http.Response('{"ok":true}', 200);
          }
          return http.Response(_canjesMasculino, 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.check_circle));
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(postCalled, isTrue);
        expect(find.byType(CanjesPendientesScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '11. Tap en rechazar llama _accion y ejecuta el flujo de éxito',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var postCalled = false;
        CanjesPendientesScreen.testClient = MockClient((req) async {
          if (req.method == 'POST') {
            postCalled = true;
            return http.Response('{"ok":true}', 200);
          }
          return http.Response(_canjesMasculino, 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(postCalled, isTrue);
        expect(find.byType(CanjesPendientesScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('12. Error en _accion muestra SnackBar de error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // El catch de _accion se dispara cuando el cliente lanza excepción
      CanjesPendientesScreen.testClient = MockClient((req) async {
        if (req.method == 'POST') throw Exception('Error de red');
        return http.Response(_canjesMasculino, 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Error al procesar acción'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      '13. _accion con testClient=null usa http.Client real (cubre fallback ??)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        // Cargamos la lista con MockClient para tener un canje visible
        CanjesPendientesScreen.testClient = MockClient((req) async {
          return http.Response(_canjesMasculino, 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        // Ahora quitamos testClient → _accion usará http.Client() real (L50 fallback)
        CanjesPendientesScreen.testClient = null;
        await tester.tap(find.byIcon(Icons.check_circle));
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump(const Duration(milliseconds: 300));
        // El cliente real falla con error de red → catch → pantalla sigue visible
        expect(find.byType(CanjesPendientesScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
