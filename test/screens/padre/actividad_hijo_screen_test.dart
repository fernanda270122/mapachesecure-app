import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/actividad_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

const _hijoTest = {'id': 'hijo-uid-123', 'nombre': 'Lucas'};

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(
          home: ActividadHijoScreen(hijo: _hijoTest),
        ),
      ),
    );

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
    ApiService.testClient = MockClient((request) async => http.Response('[]', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  group('Pruebas para ActividadHijoScreen', () {
    testWidgets(
      '1. Muestra el nombre del hijo en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.textContaining('Lucas'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra indicador de carga en estado inicial',
      (tester) async {
        await tester.pumpWidget(_wrap());
        // Verificamos el estado de carga inmediatamente, antes de que se completen las tareas asíncronas
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
      '4. El AppBar tiene foregroundColor blanco',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets(
      '5. Muestra "Resumen de Hoy" tras cargar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Resumen de Hoy'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra "Tiempo por Aplicación" en el estado cargado',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('Tiempo por Aplicaci'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Muestra mensaje cuando no hay registros de actividad',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('No hay registros'), findsOneWidget);
      },
    );
  });

  group('Pruebas con actividad', () {
    Future<void> cargar(WidgetTester tester, {required String actividadJson}) async {
      ApiService.testClient = MockClient((req) async => http.Response(actividadJson, 200));
      await tester.pumpWidget(_wrap());
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('8. Con actividad muestra Tiempo Total de Pantalla', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.youtube","minutos_uso":45}]');
      expect(find.text('Tiempo Total de Pantalla'), findsOneWidget);
    });

    testWidgets('9. Muestra YouTube cuando hay uso de YouTube', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.google.android.youtube","minutos_uso":30}]');
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('10. Muestra WhatsApp cuando hay uso de WhatsApp', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.whatsapp","minutos_uso":20}]');
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('11. Muestra Instagram cuando hay uso de Instagram', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.instagram.android","minutos_uso":25}]');
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('12. Muestra TikTok cuando hay uso de TikTok', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.zhiliao.tiktok","minutos_uso":15}]');
      expect(find.text('TikTok'), findsOneWidget);
    });

    testWidgets('13. Muestra Facebook cuando hay uso de Facebook', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.facebook.katana","minutos_uso":10}]');
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('14. Muestra Chrome cuando hay uso de Chrome', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.android.chrome","minutos_uso":12}]');
      expect(find.text('Chrome'), findsOneWidget);
    });

    testWidgets('15. Muestra Discord cuando hay uso de Discord', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.discord.app","minutos_uso":8}]');
      expect(find.text('Discord'), findsOneWidget);
    });

    testWidgets('16. Muestra Roblox cuando hay uso de Roblox', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.roblox.client","minutos_uso":60}]');
      expect(find.text('Roblox'), findsOneWidget);
    });

    testWidgets('17. Muestra nombre alternativo para apps desconocidas', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.unknown.myapp","minutos_uso":5}]');
      expect(find.text('MYAPP'), findsOneWidget);
    });

    testWidgets('18. Muestra tiempo en horas cuando supera 60 minutos', (tester) async {
      await cargar(tester, actividadJson: '[{"package_name":"com.youtube","minutos_uso":90}]');
      expect(find.text('1h 30m'), findsWidgets);
    });
  });
}
