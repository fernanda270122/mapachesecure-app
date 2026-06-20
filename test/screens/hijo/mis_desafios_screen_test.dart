import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: MisDesafiosScreen()),
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

  group('Pruebas para MisDesafiosScreen', () {
    testWidgets(
      '1. Muestra "Mis desafíos" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Mis desafíos'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra encabezado de progreso con "Pendientes"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Pendientes'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra encabezado de progreso con "Completados"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Completados'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra "Misiones activas" como subtítulo de sección',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Misiones activas'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra estado vacío cuando no hay desafíos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('¡No tienes misiones pendientes! 🦝'),
          findsOneWidget,
        );
      },
    );
  });

  group('Pruebas con datos', () {
    void stubDesafio(String tipo, String dificultad) {
      ApiService.testClient = MockClient((req) async {
        if (req.url.path.contains('/completados')) {
          return http.Response('[{"id":"1"}]', 200);
        }
        if (req.url.path.contains('/puntos')) {
          return http.Response('{"total_puntos": 20}', 200);
        }
        return http.Response(
          '[{"id":"1","titulo":"Reto $tipo","descripcion":"Descripcion","tipo":"$tipo","esta_activo":true,"dificultad":"$dificultad","puntos":10}]',
          200,
        );
      });
    }

    Future<void> cargar(WidgetTester tester, String tipo, String dificultad) async {
      stubDesafio(tipo, dificultad);
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
    }

    testWidgets('6. Muestra card de desafío cognitivo con tipo COGNITIVA', (tester) async {
      await cargar(tester, 'cognitivo', 'facil');
      expect(find.text('Reto cognitivo', skipOffstage: false), findsOneWidget);
      expect(find.text('COGNITIVA', skipOffstage: false), findsOneWidget);
    });

    testWidgets('7. Muestra card de desafío físico con tipo FISICA', (tester) async {
      await cargar(tester, 'fisico', 'medio');
      expect(find.text('FISICA', skipOffstage: false), findsOneWidget);
      expect(find.text('Reto fisico', skipOffstage: false), findsOneWidget);
    });

    testWidgets('8. Muestra card de desafío de orden con ícono correcto', (tester) async {
      await cargar(tester, 'orden', 'dificil');
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.auto_awesome, skipOffstage: false), findsOneWidget);
      expect(find.text('ORDEN', skipOffstage: false), findsOneWidget);
    });

    testWidgets('9. Muestra tipo general con ícono por defecto', (tester) async {
      await cargar(tester, 'otro', 'normal');
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.rocket_launch, skipOffstage: false), findsOneWidget);
    });

    testWidgets('10. Header muestra completados y puntos correctos', (tester) async {
      ApiService.testClient = MockClient((req) async {
        if (req.url.path.contains('/completados')) {
          return http.Response('[{},{}]', 200);
        }
        if (req.url.path.contains('/puntos')) {
          return http.Response('{"total_puntos": 30}', 200);
        }
        return http.Response('[]', 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('+30'), findsOneWidget);
    });

    testWidgets('11. Dos tipos distintos muestran dos encabezados de sección', (tester) async {
      ApiService.testClient = MockClient((req) async {
        if (req.url.path.contains('/completados')) return http.Response('[]', 200);
        if (req.url.path.contains('/puntos')) return http.Response('{"total_puntos": 0}', 200);
        return http.Response(
          '[{"id":"1","titulo":"A","descripcion":"D","tipo":"cognitivo","esta_activo":true,"dificultad":"facil","puntos":5},'
          '{"id":"2","titulo":"B","descripcion":"D","tipo":"orden","esta_activo":true,"dificultad":"dificil","puntos":10}]',
          200,
        );
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('COGNITIVA', skipOffstage: false), findsOneWidget);
      expect(find.text('ORDEN', skipOffstage: false), findsOneWidget);
    });

    testWidgets('12. Desafíos inactivos no se muestran', (tester) async {
      ApiService.testClient = MockClient((req) async {
        if (req.url.path.contains('/completados')) return http.Response('[]', 200);
        if (req.url.path.contains('/puntos')) return http.Response('{"total_puntos": 0}', 200);
        return http.Response(
          '[{"id":"1","titulo":"Oculto","descripcion":"D","tipo":"cognitivo","esta_activo":false,"dificultad":"facil","puntos":5}]',
          200,
        );
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Oculto'), findsNothing);
      expect(find.text('¡No tienes misiones pendientes! 🦝'), findsOneWidget);
    });

    testWidgets('13. Botón de altavoz no lanza error al presionar', (tester) async {
      await cargar(tester, 'cognitivo', 'facil');
      await tester.tap(find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.volume_up, skipOffstage: false).first);
      await tester.pump();
      expect(find.byType(MisDesafiosScreen), findsOneWidget);
    });

    testWidgets('14. Puntos del desafío se muestran en la card', (tester) async {
      await cargar(tester, 'cognitivo', 'facil');
      expect(find.text('10 pts', skipOffstage: false), findsOneWidget);
    });
  });
}
