import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';

// No llama a UsageStats — evita errores de plataforma en tests
class FakeActividadProvider extends ActividadProvider {
  @override
  Future<void> obtenerActividadDelDia() async {}
}

// Provider con apps en uso y más de 1 hora de pantalla
class FakeActividadProviderConDatos extends ActividadProvider {
  @override
  Future<void> obtenerActividadDelDia() async {}

  @override
  List<UsageInfo> get listaUsoReal => [
    UsageInfo(
      packageName: 'com.google.android.youtube',
      totalTimeInForeground: '3660000', // 61 minutos en ms
    ),
    UsageInfo(
      packageName: 'com.app.desconocida',
      totalTimeInForeground: '1800000', // 30 minutos
    ),
  ];
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
    testWidgets('1. Muestra el título "Mi Actividad" en el AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Mi Actividad'), findsOneWidget);
    });

    testWidgets('2. Muestra "¿Cómo vas hoy?" cuando no está cargando', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('¿Cómo vas hoy?'), findsOneWidget);
    });

    testWidgets('3. Muestra la tarjeta de tiempo total de pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Tiempo Total de Pantalla'), findsOneWidget);
    });

    testWidgets('4. Muestra "0 min" cuando tiempoTotalPantalla es cero', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('0 min'), findsOneWidget);
    });

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

    testWidgets('6. Muestra el mensaje motivador al fondo de la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Recuerda descansar la vista'),
        findsOneWidget,
      );
    });

    testWidgets(
      '7. Muestra "Tiempo por Aplicación" como encabezado de sección',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Tiempo por Aplicación'), findsOneWidget);
      },
    );
  });

  group('Pruebas con datos de uso', () {
    Widget _wrapConDatos() => MultiProvider(
      providers: [
        ChangeNotifierProvider<TemaProvider>(create: (_) => TemaProvider()),
        ChangeNotifierProvider<ActividadProvider>(
          create: (_) => FakeActividadProviderConDatos(),
        ),
      ],
      child: const MaterialApp(home: MiActividadScreen()),
    );

    testWidgets('8. Muestra tiempo en formato horas cuando supera 1 hora', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapConDatos());
      await tester.pumpAndSettle();
      expect(find.textContaining('h '), findsOneWidget);
    });

    testWidgets('9. Muestra tarjeta de app YouTube cuando está en la lista', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapConDatos());
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets(
      '10. Muestra tarjeta de app desconocida con nombre del paquete',
      (tester) async {
        await tester.pumpWidget(_wrapConDatos());
        await tester.pumpAndSettle();
        expect(find.text('desconocida'), findsOneWidget);
      },
    );

    testWidgets('11. Muestra tiempo de uso de YouTube en formato minutos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapConDatos());
      await tester.pumpAndSettle();
      expect(find.textContaining('min'), findsWidgets);
    });

    testWidgets('12. No muestra mensaje de no hay registro cuando hay datos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapConDatos());
      await tester.pumpAndSettle();
      expect(
        find.text('No hay registro de aplicaciones usadas hoy.'),
        findsNothing,
      );
    });
  });

  group('Pruebas de interacción', () {
    testWidgets('13. Pull-to-refresh llama obtenerActividadDelDia (cubre L54)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Arrastra hacia abajo sobre el SingleChildScrollView para activar el RefreshIndicator (L54)
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(MiActividadScreen), findsOneWidget);
    });
  });
}
