import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

Widget _wrap() => ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: HomeHijoScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 'hijo-uid',
      'nombre': 'Lucas',
      'tipo_avatar': 'mago',
    });
    ApiService.testClient = MockClient(
      (request) async => http.Response('[]', 200),
    );
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  // HomeHijoScreen tiene AnimationController.repeat() → NO usar pumpAndSettle()
  group('Pruebas para HomeHijoScreen', () {
    testWidgets(
      '1. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el saludo al usuario tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.textContaining('¡Hola,'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra el ícono de menú hamburguesa',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets(
      '4. El AppBar tiene foregroundColor blanco',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets(
      '5. Muestra "Desafíos disponibles:" en el cuerpo',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Desafíos disponibles:'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra mensaje cuando no hay desafíos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('No hay desafíos disponibles'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Muestra "RaccuPoints" en la tarjeta de mascota',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('RaccuPoints'), findsOneWidget);
      },
    );
  });
}
