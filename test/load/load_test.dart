import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/models/app_bloqueada.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';
import 'package:usage_stats/usage_stats.dart';

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Pruebas de carga — MapacheSecure', () {
       test(
        '1. Procesar 1000 desafíos desde JSON sin error',
        () {
          final lista = List.generate(1000, (i) => {
            'id': 'desafio_$i',
            'titulo': 'Desafío $i',
            'descripcion': 'Descripción del desafío número $i',
            'categoria': 'hogar',
            'puntos': 10,
            'estado': 'activo',
          });

          final desafios = lista.map((json) => Desafio.fromJson(json)).toList();

          expect(desafios.length, 1000);
          expect(desafios.first.id, 'desafio_0');
          expect(desafios.last.id, 'desafio_999');
        },
      );

      test(
        '2. Procesar 500 apps bloqueadas desde JSON sin error',
        () {
          final lista = List.generate(500, (i) => {
            'id': 'app_$i',
            'hijo_id': 'hijo_001',
            'nombre_app': 'App $i',
            'package_name': 'com.app.ejemplo$i',
            'requiere_desafio': i % 2 == 0,
          });

          final apps = lista.map((json) => AppBloqueada.fromJson(json)).toList();

          expect(apps.length, 500);
          expect(apps.first.packageName, 'com.app.ejemplo0');
          expect(apps.last.packageName, 'com.app.ejemplo499');
        },
      );

      test(
        '3. Calcular tiempo total con 100 registros de actividad sin error',
        () {
          SharedPreferences.setMockInitialValues({});
          final provider = ActividadProvider();

          final registros = List.generate(100, (i) => UsageInfo(
            packageName: 'com.app.ejemplo$i',
            totalTimeInForeground: '60000',
          ));

          provider.listaUsoReal.addAll(registros);

          expect(provider.tiempoTotalPantalla.inMinutes, 100);
          expect(provider.listaUsoReal.length, 100);
        },
      );

      test(
        '4. Buscar avatar por ID 10000 veces sin error',
        () {
          final ids = ['mago', 'ninja', 'gamer', 'dormilon', 'samuray', 'princes'];

          for (int i = 0; i < 10000; i++) {
            final id = ids[i % ids.length];
            final avatar = AvatarTypes.byId(id);
            expect(avatar.id, id);
          }
        },
      );
    });
  }