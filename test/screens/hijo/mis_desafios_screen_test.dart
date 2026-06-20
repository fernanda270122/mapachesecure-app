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
}
