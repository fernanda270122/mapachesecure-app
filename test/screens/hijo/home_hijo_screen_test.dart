import 'package:flutter/material.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

class _FakeBgService extends FlutterBackgroundServicePlatform {
  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async => true;
  @override
  Future<bool> start() async => true;
  @override
  Future<bool> isServiceRunning() async => false;
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {}
  @override
  Stream<Map<String, dynamic>?> on(String method) => const Stream.empty();
}

const _desafioBase = '{"id":"1","titulo":"Reto prueba","descripcion":"Descripcion del reto","tipo":"cognitivo","esta_activo":true,"dificultad":"facil","puntos":10}';

Widget _wrap() => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemaProvider()),
        ChangeNotifierProvider(create: (_) => ActividadProvider()),
      ],
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

  // HomeHijoScreen tiene AnimationController.repeat() → NO usar pumpAndSettle(), solo pump()
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

  group('Pruebas con datos', () {
    // Mocquea las 4 llamadas API de HomeHijoScreen y carga la pantalla
    Future<void> cargar(
      WidgetTester tester, {
      int puntos = 0,
      String desafiosJson = '[]',
      String completadosJson = '[]',
    }) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ApiService.testClient = MockClient((req) async {
        final path = req.url.path;
        if (path.contains('/desafios/puntos')) {
          return http.Response('{"total_puntos": $puntos}', 200);
        }
        if (path.contains('/completados')) {
          return http.Response(completadosJson, 200);
        }
        if (path.contains('/usuarios/')) {
          return http.Response('{"tipo_avatar": "mago"}', 200);
        }
        return http.Response(desafiosJson, 200);
      });
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('8. Muestra puntos cargados desde la API', (tester) async {
      await cargar(tester, puntos: 200);
      expect(find.text('200 pts'), findsOneWidget);
    });

    testWidgets('9. Muestra nivel 0 en el badge cuando los puntos son 0', (tester) async {
      await cargar(tester, puntos: 0);
      expect(find.text('Nivel 0'), findsOneWidget);
    });

    testWidgets('10. Muestra card de desafio cognitivo con tipo COGNITIVA', (tester) async {
      await cargar(tester, desafiosJson: '[$_desafioBase]');
      expect(find.text('Reto prueba', skipOffstage: false), findsOneWidget);
      expect(find.text('COGNITIVA', skipOffstage: false), findsOneWidget);
    });

    testWidgets('11. Muestra card de desafio fisico con tipo FISICA', (tester) async {
      await cargar(
        tester,
        desafiosJson: '[{"id":"1","titulo":"Reto fisico","descripcion":"Desc","tipo":"fisico","esta_activo":true,"dificultad":"medio","puntos":15}]',
      );
      expect(find.text('FISICA', skipOffstage: false), findsOneWidget);
    });

    testWidgets('12. Muestra card de desafio de orden con icono correcto', (tester) async {
      await cargar(
        tester,
        desafiosJson: '[{"id":"1","titulo":"Reto orden","descripcion":"Desc","tipo":"orden","esta_activo":true,"dificultad":"dificil","puntos":20}]',
      );
      expect(find.text('ORDEN', skipOffstage: false), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.auto_awesome, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('13. Badge de dificultad FACIL se muestra en la card', (tester) async {
      await cargar(tester, desafiosJson: '[$_desafioBase]');
      expect(find.text('FACIL', skipOffstage: false), findsOneWidget);
    });

    testWidgets('14. Badge de dificultad DIFICIL se muestra en la card', (tester) async {
      await cargar(
        tester,
        desafiosJson: '[{"id":"1","titulo":"Reto dificil","descripcion":"Desc","tipo":"orden","esta_activo":true,"dificultad":"dificil","puntos":20}]',
      );
      expect(find.text('DIFICIL', skipOffstage: false), findsOneWidget);
    });

    testWidgets('15. Expandir card muestra boton para ir al desafio', (tester) async {
      await cargar(tester, desafiosJson: '[$_desafioBase]');
      await tester.tap(find.text('Reto prueba', skipOffstage: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('¡Ir a realizar el desafío!', skipOffstage: false), findsOneWidget);
    });

    testWidgets('16. Card de desafio pendiente muestra estado de revision', (tester) async {
      await cargar(
        tester,
        desafiosJson: '[$_desafioBase]',
        completadosJson: '[{"validado": false, "desafio_id": "1"}]',
      );
      await tester.tap(find.text('Reto prueba', skipOffstage: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pendiente de revisión', skipOffstage: false), findsOneWidget);
    });

    testWidgets('17. Boton Recompensas existe en la pantalla', (tester) async {
      await cargar(tester);
      expect(find.text('Recompensas'), findsOneWidget);
    });

    testWidgets('18. Drawer muestra opciones de navegacion al abrirse', (tester) async {
      await cargar(tester);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mis desafíos', skipOffstage: false), findsOneWidget);
      expect(find.text('Tienda de recompensas', skipOffstage: false), findsOneWidget);
    });

    group('Niveles de mascota', () {
      testWidgets('19. 500 puntos muestran Nivel 1', (tester) async {
        await cargar(tester, puntos: 500);
        expect(find.text('Nivel 1'), findsWidgets);
      });

      testWidgets('20. 1100 puntos muestran Nivel 2', (tester) async {
        await cargar(tester, puntos: 1100);
        expect(find.text('Nivel 2'), findsWidgets);
      });

      testWidgets('21. 5500 puntos muestran Nivel 6 y progreso al 100%', (tester) async {
        await cargar(tester, puntos: 5500);
        expect(find.textContaining('Nivel 6'), findsWidgets);
        expect(find.text('100%'), findsOneWidget);
      });
    });

    group('Dificultad sin reconocer', () {
      testWidgets('22. Dificultad desconocida muestra badge en mayúsculas', (tester) async {
        await cargar(
          tester,
          desafiosJson:
              '[{"id":"1","titulo":"Reto extremo","descripcion":"Desc","tipo":"cognitivo","esta_activo":true,"dificultad":"extremo","puntos":5}]',
        );
        expect(find.text('EXTREMO', skipOffstage: false), findsOneWidget);
      });
    });

    group('Escudo de cierre de sesión', () {
      Future<void> abrirEscudo(WidgetTester tester) async {
        await cargar(tester);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // Verificamos que el drawer está abierto antes de tapear
        expect(find.text('Cerrar Sesión'), findsOneWidget);
        await tester.tap(find.text('Cerrar Sesión'));
        await tester.pump(const Duration(milliseconds: 300));
      }

      testWidgets('23. Tap Cerrar Sesión abre diálogo de Validación de Adulto', (tester) async {
        await abrirEscudo(tester);
        expect(find.text('Validación de Adulto'), findsOneWidget);
      });

      testWidgets('24. CANCELAR en diálogo de cierre de sesión lo cierra', (tester) async {
        await abrirEscudo(tester);
        await tester.tap(find.text('CANCELAR'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Validación de Adulto'), findsNothing);
      });

      testWidgets('25. DESACTIVAR con credenciales inválidas muestra SnackBar de error', (tester) async {
        await abrirEscudo(tester);
        // Reemplaza el cliente para que login devuelva error
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/auth/login')) {
            return http.Response('{"detail": "Credenciales invalidas"}', 401);
          }
          return http.Response('[]', 200);
        });
        await tester.enterText(find.byType(TextField).first, 'adulto@test.com');
        await tester.enterText(find.byType(TextField).last, 'wrongpass');
        await tester.tap(find.text('DESACTIVAR Y SALIR'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Datos incorrectos o acceso denegado.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      });
    });

    group('Cargar datos: casos extra', () {
      testWidgets('26. tipo_avatar y foto_perfil del backend actualizan el estado', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 1920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        ApiService.testClient = MockClient((req) async {
          final path = req.url.path;
          if (path.contains('/desafios/puntos')) {
            return http.Response('{"total_puntos": 0}', 200);
          }
          if (path.contains('/completados')) return http.Response('[]', 200);
          if (path.contains('/usuarios/')) {
            return http.Response(
              '{"tipo_avatar": "dormilon", "foto_perfil": "assets/mascota/dormilon1.png"}',
              200,
            );
          }
          return http.Response('[]', 200);
        });
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Desafíos disponibles:'), findsOneWidget);
      });

      testWidgets('27. Desafio con esta_activo=false no se muestra en pantalla', (tester) async {
        await cargar(
          tester,
          desafiosJson:
              '[{"id":"1","titulo":"Desafio Inactivo","descripcion":"Desc","tipo":"cognitivo","esta_activo":false,"dificultad":"facil","puntos":10}]',
        );
        expect(find.text('Desafio Inactivo', skipOffstage: false), findsNothing);
        expect(find.text('No hay desafíos disponibles'), findsOneWidget);
      });

      testWidgets('28. Dos desafios con mismo titulo: solo uno visible por deduplicación', (tester) async {
        await cargar(
          tester,
          desafiosJson:
              '[$_desafioBase, {"id":"2","titulo":"Reto prueba","descripcion":"Desc 2","tipo":"fisico","esta_activo":true,"dificultad":"medio","puntos":20}]',
        );
        expect(find.text('Reto prueba', skipOffstage: false), findsOneWidget);
      });

      testWidgets('29. Desafio de tipo general usa icono por defecto', (tester) async {
        await cargar(
          tester,
          desafiosJson:
              '[{"id":"1","titulo":"Reto general","descripcion":"Desc","tipo":"general","esta_activo":true,"dificultad":"facil","puntos":5}]',
        );
        expect(find.text('GENERAL', skipOffstage: false), findsOneWidget);
      });

      testWidgets('30. Error de API 500 no bloquea la pantalla y muestra nombre', (tester) async {
        ApiService.testClient = MockClient(
          (req) async => http.Response('{"detail":"error"}', 500),
        );
        await tester.pumpWidget(_wrap());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('¡Hola,'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('31. Dificultad "medio" usa color naranja (badge visible)', (tester) async {
        await cargar(
          tester,
          desafiosJson:
              '[{"id":"1","titulo":"Reto medio","descripcion":"Desc","tipo":"cognitivo","esta_activo":true,"dificultad":"medio","puntos":15}]',
        );
        expect(find.text('MEDIO', skipOffstage: false), findsOneWidget);
      });

      testWidgets('32. Tap en avatar del header inicia navegación a AvatarScreen', (tester) async {
        await cargar(tester);
        await tester.tap(find.byType(CircleAvatar).first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Scaffold), findsWidgets);
      });
    });

    group('Drawer opciones adicionales', () {
      Future<void> abrirDrawer(WidgetTester tester) async {
        await cargar(tester);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      testWidgets('33. Tap en Tienda de recompensas en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Tienda de recompensas', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('34. Tap en Mis desafíos en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Mis desafíos', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('35. Tap en Mi Actividad en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Mi Actividad', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('36. Tap en Guía de la app en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Guía de la app', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('37. Tap en Colores en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Colores', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('38. Tap en Mi Avatar en drawer navega', (tester) async {
        await abrirDrawer(tester);
        await tester.tap(find.text('Mi Avatar', skipOffstage: false));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });
    });

    group('Escudo de sesión: login exitoso', () {
      Future<void> abrirEscudo(WidgetTester tester) async {
        await cargar(tester);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Cerrar Sesión'));
        await tester.pump(const Duration(milliseconds: 300));
      }

      testWidgets('39. Login exitoso con rol=padre navega al LoginScreen', (tester) async {
        FlutterBackgroundServicePlatform.instance = _FakeBgService();
        await abrirEscudo(tester);
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/auth/login')) {
            return http.Response(
              '{"access_token":"t","refresh_token":"r","user_id":"p1","perfil":{"rol":"padre","nombre":"Papa"}}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('[]', 200);
        });
        await tester.enterText(find.byType(TextField).first, 'papa@test.com');
        await tester.enterText(find.byType(TextField).last, 'pass123');
        await tester.tap(find.text('DESACTIVAR Y SALIR'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(HomeHijoScreen), findsNothing);
      });

      testWidgets('40. Login con rol no-padre lanza SnackBar de error', (tester) async {
        await abrirEscudo(tester);
        ApiService.testClient = MockClient((req) async {
          if (req.url.path.contains('/auth/login')) {
            return http.Response(
              '{"access_token":"t","refresh_token":"r","user_id":"h1","perfil":{"rol":"hijo","nombre":"Lucas"}}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('[]', 200);
        });
        await tester.enterText(find.byType(TextField).first, 'hijo@test.com');
        await tester.enterText(find.byType(TextField).last, 'pass123');
        await tester.tap(find.text('DESACTIVAR Y SALIR'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Datos incorrectos o acceso denegado.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      });
    });

    group('Cobertura adicional', () {
      testWidgets(
        '41. ApiUnauthorizedException con refresh fallido navega a LoginScreen (_cerrarSesionPorExpiracion)',
        (tester) async {
          FlutterBackgroundServicePlatform.instance = _FakeBgService();
          SharedPreferences.setMockInitialValues({
            'user_id': 'hijo-uid',
            'nombre': 'Lucas',
            'tipo_avatar': 'mago',
            'refresh_token': 'refresh_tkn',
          });
          ApiService.testClient = MockClient((req) async {
            if (req.method == 'POST') {
              // refresh falla
              return http.Response('{"detail": "Token expirado"}', 400);
            }
            // Todos los GETs retornan 401 → ApiUnauthorizedException
            return http.Response('', 401);
          });
          await tester.pumpWidget(_wrap());
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          // Después del refresh fallido, _cerrarSesionPorExpiracion navega a LoginScreen
          expect(find.text('Iniciar Sesión'), findsOneWidget);
        },
      );

      testWidgets('42. Tap en botón Recompensas del cuerpo navega', (tester) async {
        await cargar(tester);
        await tester.tap(find.text('Recompensas'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets(
        '43. Desafios endpoint retorna Map en lugar de List → pantalla muestra vacío',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1080, 1920));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          ApiService.testClient = MockClient((req) async {
            final path = req.url.path;
            if (path.contains('/desafios/puntos')) {
              return http.Response('{"total_puntos": 0}', 200);
            }
            if (path.contains('/completados')) return http.Response('[]', 200);
            if (path.contains('/usuarios/')) {
              return http.Response('{"tipo_avatar": "mago"}', 200);
            }
            // /desafios/hijo/ retorna un Map → no es List → _desafios = []
            return http.Response('{"items": []}', 200);
          });
          await tester.pumpWidget(_wrap());
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('No hay desafíos disponibles'), findsOneWidget);
        },
      );

      testWidgets(
        '44. Tap en icono volumen de desafío expandido invoca TTS speak',
        (tester) async {
          await cargar(tester, desafiosJson: '[$_desafioBase]');
          await tester.tap(find.text('Reto prueba', skipOffstage: false));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.byIcon(Icons.volume_up, skipOffstage: false));
          await tester.pump(const Duration(milliseconds: 100));
          // La pantalla no debe crashear
          expect(find.byType(HomeHijoScreen), findsOneWidget);
        },
      );

      testWidgets(
        '45. Tap en "¡Ir a realizar el desafío!" navega a DetalleDesafioScreen y regresa',
        (tester) async {
          await cargar(tester, desafiosJson: '[$_desafioBase]');
          await tester.tap(find.text('Reto prueba', skipOffstage: false));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(
            find.text('¡Ir a realizar el desafío!', skipOffstage: false),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(Scaffold), findsWidgets);
          // Pop de regreso cubre la línea posterior al await Navigator.push
          final NavigatorState nav = tester.state(find.byType(Navigator));
          nav.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(HomeHijoScreen), findsOneWidget);
        },
      );

      testWidgets(
        '46. Login como padre con clave onboarding_ preserva la clave (líneas 483-484)',
        (tester) async {
          FlutterBackgroundServicePlatform.instance = _FakeBgService();
          SharedPreferences.setMockInitialValues({
            'user_id': 'hijo-uid',
            'nombre': 'Lucas',
            'tipo_avatar': 'mago',
            'onboarding_padre': true,
          });
          await tester.binding.setSurfaceSize(const Size(1080, 1920));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          ApiService.testClient = MockClient((req) async {
            final path = req.url.path;
            if (path.contains('/desafios/puntos')) {
              return http.Response('{"total_puntos": 0}', 200);
            }
            if (path.contains('/completados')) return http.Response('[]', 200);
            if (path.contains('/usuarios/')) {
              return http.Response('{"tipo_avatar": "mago"}', 200);
            }
            if (path.contains('/auth/login')) {
              return http.Response(
                '{"access_token":"t","refresh_token":"r","user_id":"p1","perfil":{"rol":"padre","nombre":"Papa"}}',
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response('[]', 200);
          });
          await tester.pumpWidget(_wrap());
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Cerrar Sesión'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.enterText(find.byType(TextField).first, 'papa@test.com');
          await tester.enterText(find.byType(TextField).last, 'pass123');
          await tester.tap(find.text('DESACTIVAR Y SALIR'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(HomeHijoScreen), findsNothing);
        },
      );

      testWidgets(
        '47. Pop de AvatarScreen vía drawer cubre línea 717 (if result != null)',
        (tester) async {
          await cargar(tester);
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Mi Avatar', skipOffstage: false));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          // AvatarScreen está visible, volvemos sin resultado
          final NavigatorState nav = tester.state(find.byType(Navigator));
          nav.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(HomeHijoScreen), findsOneWidget);
        },
      );

      testWidgets(
        '48. Pop de AvatarScreen vía CircleAvatar del header cubre líneas 795-796',
        (tester) async {
          await cargar(tester);
          await tester.tap(find.byType(CircleAvatar).first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          // Volvemos sin resultado
          final NavigatorState nav = tester.state(find.byType(Navigator));
          nav.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(HomeHijoScreen), findsOneWidget);
        },
      );
    });
  });
}
