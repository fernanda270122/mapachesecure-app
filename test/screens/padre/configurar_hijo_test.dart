import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/configurar_hijo.dart';
import 'package:mapachesecure_app/services/api_service.dart';

const _hijoTest = {
  'id': 'hijo-id',
  'nombre': 'Lucas',
  'email': 'lucas@test.com',
  'rol': 'hijo',
};

Widget _wrap() => ScreenUtilInit(
  designSize: const Size(375, 812),
  minTextAdapt: true,
  builder: (_, __) => ChangeNotifierProvider(
    create: (_) => TemaPadreProvider(),
    child: const MaterialApp(home: ConfigurarHijoScreen(hijo: _hijoTest)),
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
    ApiService.testClient = MockClient(
      (request) async => http.Response('[]', 200),
    );
  });

  tearDown(() {
    ApiService.testClient = null;
  });

  // ConfigurarHijoScreen tiene Timer.periodic → NO usar pumpAndSettle()
  group('Pruebas para ConfigurarHijoScreen', () {
    testWidgets('1. Muestra el nombre del hijo en el AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      expect(find.textContaining('Lucas'), findsWidgets);
    });

    testWidgets('2. Muestra el ListView tras cargar', (tester) async {
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('3. Contiene un Scaffold como raíz de la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('4. El AppBar tiene foregroundColor blanco', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.foregroundColor, Colors.white);
    });

    testWidgets('5. Muestra cards en el panel de configuración', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('6. Muestra texto cuando no hay bloqueos configurados', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      expect(find.text('No hay bloqueos configurados'), findsOneWidget);
    });

    testWidgets(
      '7. Muestra lista de apps populares (TikTok, YouTube, Instagram)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('TikTok'), findsOneWidget);
        expect(find.text('YouTube'), findsOneWidget);
        expect(find.text('Instagram'), findsOneWidget);
      },
    );

    testWidgets('8. Tap en botón Horario muestra el formulario de bloqueo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      await tester.tap(find.text('Horario'));
      await tester.pump();
      expect(find.text('Selecciona el horario'), findsOneWidget);
      expect(find.text('Repetir los días:'), findsOneWidget);
      expect(find.text('Guardar horario'), findsOneWidget);
    });

    testWidgets('9. Guardar horario sin días muestra SnackBar de error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      await tester.tap(find.text('Horario'));
      await tester.pump();
      await tester.tap(find.text('Guardar horario'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Selecciona al menos un día'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      '10. Guardar horario con día pero sin apps muestra SnackBar de error',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Horario'));
        await tester.pump();
        // Seleccionamos día 'Lun'
        await tester.tap(find.text('Lun'));
        await tester.pump();
        await tester.tap(find.text('Guardar horario'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text('Selecciona al menos una app para este horario'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '11. Pantalla con bloqueo total muestra BLOQUEO TOTAL DISPOSITIVO',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              '[{"id":"1","tipo":"total","dias_semana":"[0,1,2,3,4,5,6]","hora_inicio":"00:00","hora_fin":"23:59","package_names":""}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('BLOQUEO TOTAL DISPOSITIVO'), findsOneWidget);
      },
    );

    testWidgets(
      '12. Pantalla con bloqueo horario muestra BLOQUEO POR HORARIO y apps restringidas',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              '[{"id":"2","tipo":"horario","dias_semana":"[1,2]","hora_inicio":"20:00","hora_fin":"22:00","package_names":"com.zhiliaoapp.musically,com.google.android.youtube"}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('BLOQUEO POR HORARIO'), findsOneWidget);
        expect(find.text('TikTok'), findsWidgets);
      },
    );

    testWidgets(
      '13. Bloqueo horario con hora válida renderiza la pantalla correctamente',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              '[{"id":"3","tipo":"horario","dias_semana":"[1,2,3,4,5]","hora_inicio":"20:00","hora_fin":"22:00","package_names":"com.test.pkg"}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        // La evaluación de _estaBloqueadaPorHorario ocurre en build para cada app
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '14. Bloqueo horario con hora inválida no rompe la pantalla (catch interno)',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              '[{"id":"4","tipo":"horario","dias_semana":"[1]","hora_inicio":"INVALID","hora_fin":"22:00","package_names":"com.zhiliaoapp.musically"}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        // El catch en _estaBloqueadaPorHorario absorbe el error — la pantalla sigue funcionando
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('BLOQUEO POR HORARIO'), findsOneWidget);
      },
    );

    testWidgets(
      '15. Toggle Bloqueo Total llama a la API y muestra diálogo de retraso',
      (tester) async {
        var postCalled = false;
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'POST' && req.url.path.contains('/bloqueos/')) {
            postCalled = true;
            return http.Response('{"id":"new"}', 200);
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        // El primer SwitchListTile es Bloqueo Total (value=false → tap activa = POST)
        await tester.tap(find.byType(SwitchListTile).first);
        await _pumpLoaded(tester);
        expect(postCalled, true);
        // Avanzamos 6s para que el Future.delayed(5s) del diálogo expire y se limpie
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets(
      '16. Pantalla con apps bloqueadas muestra estado Bloqueada en la app',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/apps/')) {
            return http.Response(
              '[{"id":"1","package_name":"com.zhiliaoapp.musically","nombre_app":"TikTok"}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        expect(find.text('Bloqueada'), findsWidgets);
      },
    );

    testWidgets('17. Tap en switch de app bloqueada llama a delete en la API', (
      tester,
    ) async {
      var deleteCalled = false;
      ApiService.testClient = MockClient((req) async {
        if (req.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('{}', 200);
        }
        if (req.url.path.contains('/apps/')) {
          return http.Response(
            '[{"id":"app-id-1","package_name":"com.zhiliaoapp.musically","nombre_app":"TikTok"}]',
            200,
          );
        }
        return http.Response('[]', 200);
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      // TikTok tiene value=true (bloqueada); el Bloqueo Total tiene value=false
      // Tapamos el Switch con value=true para desbloquear TikTok → llama a DELETE
      await tester.tap(
        find.byWidgetPredicate((w) => w is Switch && w.value == true).first,
      );
      await _pumpLoaded(tester);
      expect(deleteCalled, true);
    });

    testWidgets('18. Tap en eliminar bloqueo horario llama a DELETE y recarga', (
      tester,
    ) async {
      var deleteCalled = false;
      ApiService.testClient = MockClient((req) async {
        if (req.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('{}', 200);
        }
        if (req.url.path.contains('/bloqueos/')) {
          return http.Response(
            deleteCalled
                ? '[]'
                : '[{"id":"blq-1","tipo":"horario","dias_semana":"[1]","hora_inicio":"20:00","hora_fin":"22:00","package_names":"com.zhiliaoapp.musically"}]',
            200,
          );
        }
        return http.Response('[]', 200);
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await _pumpLoaded(tester);
      expect(deleteCalled, true);
      expect(find.textContaining('Error al eliminar'), findsNothing);
      // Drenar el diálogo de retraso (Future.delayed 5s)
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('19. Error al eliminar bloqueo muestra SnackBar de error', (
      tester,
    ) async {
      ApiService.testClient = MockClient((req) async {
        if (req.method == 'DELETE') {
          return http.Response('{"detail":"forbidden"}', 403);
        }
        if (req.url.path.contains('/bloqueos/')) {
          return http.Response(
            '[{"id":"blq-1","tipo":"horario","dias_semana":"[1]","hora_inicio":"20:00","hora_fin":"22:00","package_names":"com.zhiliaoapp.musically"}]',
            200,
          );
        }
        return http.Response('[]', 200);
      });
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await _pumpLoaded(tester);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await _pumpLoaded(tester);
      expect(find.text('Error al eliminar bloqueo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      '20. Toggle Bloqueo Total a false llama a DELETE del bloqueo total',
      (tester) async {
        var deleteCalled = false;
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'DELETE') {
            deleteCalled = true;
            return http.Response('{}', 200);
          }
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              deleteCalled
                  ? '[]'
                  : '[{"id":"tot-1","tipo":"total","dias_semana":"[0,1,2,3,4,5,6]","hora_inicio":"00:00","hora_fin":"23:59","package_names":""}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        // El switch de Bloqueo Total está encendido → tap llama _toggleBloqueoTotal(false)
        await tester.tap(find.byType(SwitchListTile).first);
        await _pumpLoaded(tester);
        expect(deleteCalled, true);
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets(
      '21. Error al desactivar Bloqueo Total muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'DELETE') {
            return http.Response('{"detail":"error"}', 500);
          }
          if (req.url.path.contains('/bloqueos/')) {
            return http.Response(
              '[{"id":"tot-1","tipo":"total","dias_semana":"[0,1,2,3,4,5,6]","hora_inicio":"00:00","hora_fin":"23:59","package_names":""}]',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.byType(SwitchListTile).first);
        await _pumpLoaded(tester);
        expect(find.text('Error al modificar Bloqueo Total'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '22. Guardar horario con día y app seleccionados llama a POST en la API',
      (tester) async {
        var postCalled = false;
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'POST' && req.url.path.contains('/bloqueos/')) {
            postCalled = true;
            return http.Response('{"id":"new"}', 200);
          }
          return http.Response('[]', 200);
        });
        await tester.binding.setSurfaceSize(const Size(1080, 3000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        // Activar modo horario
        await tester.tap(find.text('Horario'));
        await tester.pump();
        // Seleccionar día Lun (cubre _diasSeleccionados.add)
        await tester.tap(find.text('Lun'));
        await tester.pump();
        // Seleccionar TikTok en modo horario (índice 1 = primer app tras Bloqueo Total)
        await tester.tap(find.byType(Switch).at(1));
        await tester.pump();
        // Guardar horario
        await tester.tap(find.text('Guardar horario'));
        await _pumpLoaded(tester);
        expect(postCalled, true);
        expect(find.textContaining('Error al conectar'), findsNothing);
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets(
      '23. Guardar horario con error de API muestra SnackBar de error',
      (tester) async {
        ApiService.testClient = MockClient((req) async {
          if (req.method == 'POST' && req.url.path.contains('/bloqueos/')) {
            return http.Response('{"detail":"error"}', 500);
          }
          return http.Response('[]', 200);
        });
        await tester.binding.setSurfaceSize(const Size(1080, 3000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Horario'));
        await tester.pump();
        await tester.tap(find.text('Lun'));
        await tester.pump();
        await tester.tap(find.byType(Switch).at(1));
        await tester.pump();
        await tester.tap(find.text('Guardar horario'));
        await _pumpLoaded(tester);
        expect(find.text('Error al conectar con el servidor'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('24. Navegar fuera de la pantalla llama dispose sin crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => TemaPadreProvider(),
            child: MaterialApp(
              routes: {
                '/': (ctx) => Scaffold(
                  body: Builder(
                    builder: (c) => ElevatedButton(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ConfigurarHijoScreen(hijo: _hijoTest),
                        ),
                      ),
                      child: const Text('Ir'),
                    ),
                  ),
                ),
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ir'));
      await _pumpLoaded(tester);
      expect(find.byType(ConfigurarHijoScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ConfigurarHijoScreen), findsNothing);
    });

    testWidgets(
      '25. Deseleccionar día ya elegido en selectorDias cubre el else branch',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_wrap());
        await _pumpLoaded(tester);
        await tester.tap(find.text('Horario'));
        await tester.pump();
        // Primer tap: seleccionar Lun
        await tester.tap(find.text('Lun'));
        await tester.pump();
        // Segundo tap: deseleccionar Lun (cubre _diasSeleccionados.remove)
        await tester.tap(find.text('Lun'));
        await tester.pump();
        expect(find.byType(ConfigurarHijoScreen), findsOneWidget);
      },
    );
  });
}
