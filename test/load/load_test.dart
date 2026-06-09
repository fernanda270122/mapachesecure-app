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
      '1. Procesar 1000 desafíos desde JSON en menos de 500ms',
      () {
        final lista = List.generate(1000, (i) => {
          'id': 'desafio_$i',
          'titulo': 'Desafío $i',
          'descripcion': 'Descripción del desafío número $i',
          'categoria': 'hogar',
          'puntos': 10,
          'estado': 'activo',
        });

        final stopwatch = Stopwatch()..start();
        final desafios = lista.map((json) => Desafio.fromJson(json)).toList();
        stopwatch.stop();

        expect(desafios.length, 1000);
        expect(desafios.first.id, 'desafio_0');
        expect(desafios.last.id, 'desafio_999');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: 'Parsear 1000 desafíos tardó ${stopwatch.elapsedMilliseconds}ms — supera el umbral de 500ms',
        );
      },
    );

    test(
      '2. Procesar 500 apps bloqueadas desde JSON en menos de 300ms',
      () {
        final lista = List.generate(500, (i) => {
          'id': 'app_$i',
          'hijo_id': 'hijo_001',
          'nombre_app': 'App $i',
          'package_name': 'com.app.ejemplo$i',
          'requiere_desafio': i % 2 == 0,
        });

        final stopwatch = Stopwatch()..start();
        final apps = lista.map((json) => AppBloqueada.fromJson(json)).toList();
        stopwatch.stop();

        expect(apps.length, 500);
        expect(apps.first.packageName, 'com.app.ejemplo0');
        expect(apps.last.packageName, 'com.app.ejemplo499');
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(300),
          reason: 'Parsear 500 apps tardó ${stopwatch.elapsedMilliseconds}ms — supera el umbral de 300ms',
        );
      },
    );

    test(
      '3. Calcular tiempo total con 100 registros de actividad en menos de 200ms',
      () {
        SharedPreferences.setMockInitialValues({});
        final provider = ActividadProvider();

        final registros = List.generate(100, (i) => UsageInfo(
          packageName: 'com.app.ejemplo$i',
          totalTimeInForeground: '60000',
        ));

        final stopwatch = Stopwatch()..start();
        provider.listaUsoReal.addAll(registros);
        final total = provider.tiempoTotalPantalla;
        stopwatch.stop();

        expect(total.inMinutes, 100);
        expect(provider.listaUsoReal.length, 100);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'Calcular 100 registros tardó ${stopwatch.elapsedMilliseconds}ms — supera el umbral de 200ms',
        );
      },
    );

    test(
      '4. Buscar avatar por ID 10000 veces en menos de 1000ms',
      () {
        final ids = ['mago', 'ninja', 'gamer', 'dormilon', 'samuray', 'princes'];

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 10000; i++) {
          final id = ids[i % ids.length];
          final avatar = AvatarTypes.byId(id);
          expect(avatar.id, id);
        }
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: '10000 búsquedas de avatar tardaron ${stopwatch.elapsedMilliseconds}ms — supera el umbral de 1000ms',
        );
      },
    );
  });
}
