import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';

// No llama a UsageStats — evita errores de plataforma en tests
class FakeActividadProvider extends ActividadProvider {
  @override
  Future<void> obtenerActividadDelDia() async {}
}

Widget _wrap({ActividadProvider? actividad}) => MultiProvider(
      providers: [
        ChangeNotifierProvider<TemaProvider>(create: (_) => TemaProvider()),
        ChangeNotifierProvider<ActividadProvider>(
          create: (_) => actividad ?? FakeActividadProvider(),
        ),
      ],
      child: const MaterialApp(home: MiActividadScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para MiActividadScreen', () {
    testWidgets(
      '1. Muestra el título "Mi Actividad" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Mi Actividad'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra "¿Cómo vas hoy?" cuando no está cargando',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('¿Cómo vas hoy?'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra la tarjeta de tiempo total de pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Tiempo Total de Pantalla'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra "0 min" cuando tiempoTotalPantalla es cero',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('0 min'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra mensaje "No hay registro" cuando la lista de uso está vacía',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('No hay registro de aplicaciones usadas hoy.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Muestra el mensaje motivador al fondo de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Recuerda descansar la vista'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Muestra "Tiempo por Aplicación" como encabezado de sección',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Tiempo por Aplicación'), findsOneWidget);
      },
    );
  });
}
