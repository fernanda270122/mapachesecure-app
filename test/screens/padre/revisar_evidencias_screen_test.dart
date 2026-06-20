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
}
