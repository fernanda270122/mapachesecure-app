import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/desafios_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

const _hijoTest = {'id': 'hijo-id', 'nombre': 'Lucas'};

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(
          home: DesafiosHijoScreen(hijo: _hijoTest),
        ),
      ),
    );

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
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

  group('Pruebas para DesafiosHijoScreen', () {
    testWidgets(
      '1. Muestra el nombre del hijo en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.textContaining('Lucas'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el botón de generar desafíos con IA',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.byType(ElevatedButton), findsOneWidget);
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
      '5. Muestra el texto del botón de generar con IA',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Generar nuevos con IA'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Muestra mensaje cuando no hay desafíos asignados',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.textContaining('No hay desafíos asignados'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Desafíos de tipo cognitiva se muestran en la sección Cognitiva',
      (tester) async {
        ApiService.testClient = MockClient((req) async => http.Response(
          '[{"id":"1","titulo":"Reto cognitivo","descripcion":"Desc","tipo":"cognitiva","esta_activo":true,"dificultad":"facil","puntos":10}]',
          200,
        ));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Cognitiva'), findsOneWidget);
        expect(find.text('Reto cognitivo'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Desafíos de tipo fisica se muestran en la sección Física',
      (tester) async {
        ApiService.testClient = MockClient((req) async => http.Response(
          '[{"id":"2","titulo":"Reto físico","descripcion":"Desc fisica","tipo":"fisica","esta_activo":false,"dificultad":"medio","puntos":20}]',
          200,
        ));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Física'), findsOneWidget);
        expect(find.text('Reto físico'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Desafíos de tipo hogar se muestran en la sección Hogar',
      (tester) async {
        ApiService.testClient = MockClient((req) async => http.Response(
          '[{"id":"3","titulo":"Tarea de hogar","descripcion":"Limpiar cuarto","tipo":"hogar","esta_activo":true,"dificultad":"dificil","puntos":30}]',
          200,
        ));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Hogar'), findsOneWidget);
        expect(find.text('Tarea de hogar'), findsOneWidget);
      },
    );

    testWidgets(
      '10. difficultyToBackend convierte correctamente Fácil/Medio/Difícil',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        final state = tester.state(find.byType(DesafiosHijoScreen)) as dynamic;
        expect(state.difficultyToBackend('Fácil'), 'facil');
        expect(state.difficultyToBackend('Medio'), 'medio');
        expect(state.difficultyToBackend('Difícil'), 'dificil');
        expect(state.difficultyToBackend('OTRO'), 'otro');
      },
    );

    testWidgets(
      '11. Tap en Switch con error de API muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/actualizar_estado')) {
            return http.Response('{"detail": "Error al actualizar"}', 400);
          }
          return http.Response(
            '[{"id":"1","titulo":"Reto cognitivo","descripcion":"Desc","tipo":"cognitiva","esta_activo":true,"dificultad":"facil","puntos":10}]',
            200,
          );
        });
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.byType(Switch).first);
        await _pumpLoaded(tester);
        expect(find.textContaining('Error al cambiar estado'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '12. Modal de generación IA se abre con Categoría y Dificultad',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Generar nuevos con IA'));
        await tester.pumpAndSettle();
        expect(find.text('Categoría'), findsOneWidget);
        expect(find.text('Dificultad'), findsOneWidget);
        expect(find.text('Generar misiones'), findsOneWidget);
      },
    );

    testWidgets(
      '13. Tap Generar misiones con error de IA muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/ia/generar')) {
            return http.Response('{"detail": "Servicio IA no disponible"}', 503);
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Generar nuevos con IA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Generar misiones'));
        await _pumpLoaded(tester);
        expect(find.textContaining('Error'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
