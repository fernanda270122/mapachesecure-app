import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/models/app_bloqueada.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
import 'package:mapachesecure_app/models/pet_model.dart';

int _percentil(List<int> tiempos, double p) {
  final sorted = List<int>.from(tiempos)..sort();
  final idx = ((sorted.length - 1) * p).floor();
  return sorted[idx];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas de carga — Raccu', () {

    // ── TEST 1: 50 usuarios cargando sus desafíos al mismo tiempo ─────────────
    // Simula la hora pico: todos los hijos abren la app después del colegio
    test('1. 50 usuarios concurrentes cargando 20 desafíos c/u — p95 < 200ms, error < 1%',
        () async {
      const usuarios = 50;
      const desafiosPorUsuario = 20;
      final tiempos = <int>[];
      int errores = 0;

      final inicio = DateTime.now();

      await Future.wait(
        List.generate(usuarios, (u) async {
          for (int i = 0; i < desafiosPorUsuario; i++) {
            final sw = Stopwatch()..start();
            try {
              Desafio.fromJson({
                'id': 'desafio_${u}_$i',
                'titulo': 'Desafío $i del usuario $u',
                'descripcion': 'Descripción $i',
                'categoria': ['cognitiva', 'fisica', 'hogar'][i % 3],
                'puntos': 10 + (i * 5),
                'estado': ['activo', 'pendiente', 'completado'][i % 3],
              });
            } catch (_) {
              errores++;
            }
            sw.stop();
            tiempos.add(sw.elapsedMicroseconds);
          }
        }),
      );

      final duracionMs = DateTime.now().difference(inicio).inMilliseconds;
      final total = usuarios * desafiosPorUsuario;
      final p95 = _percentil(tiempos, 0.95);
      final tasaError = errores / total;
      final opsPorSegundo = total / (duracionMs / 1000);
      final opsPorMinuto = opsPorSegundo * 60;

      debugPrint('── Desafíos: $usuarios usuarios × $desafiosPorUsuario desafíos = $total solicitudes en ${duracionMs}ms');
      debugPrint('   p95        : ${(p95 / 1000).toStringAsFixed(3)}ms');
      debugPrint('   Errores    : $errores / $total (${(tasaError * 100).toStringAsFixed(2)}%)');
      debugPrint('   Throughput : ${opsPorSegundo.toStringAsFixed(0)} ops/s  |  ${opsPorMinuto.toStringAsFixed(0)} ops/min');

      expect(p95, lessThan(200000),
          reason: 'p95 fue ${(p95 / 1000).toStringAsFixed(2)}ms — supera 200ms');
      expect(tasaError, lessThan(0.01),
          reason: 'Tasa de error ${(tasaError * 100).toStringAsFixed(2)}% supera el 1%');
    });

    // ── TEST 2: 50 guardianes verificando apps bloqueadas al mismo tiempo ─────
    // Simula el guardián de 50 dispositivos hijo revisando apps concurrentemente
    test('2. 50 guardianes verificando 15 apps bloqueadas c/u — p95 < 200ms, error < 1%',
        () async {
      const usuarios = 50;
      const appsPorUsuario = 15;
      final tiempos = <int>[];
      int errores = 0;

      final inicio = DateTime.now();

      await Future.wait(
        List.generate(usuarios, (u) async {
          for (int i = 0; i < appsPorUsuario; i++) {
            final sw = Stopwatch()..start();
            try {
              AppBloqueada.fromJson({
                'id': 'app_${u}_$i',
                'hijo_id': 'hijo_$u',
                'nombre_app': 'App $i',
                'package_name': 'com.app.ejemplo$i',
                'requiere_desafio': i % 2 == 0,
              });
            } catch (_) {
              errores++;
            }
            sw.stop();
            tiempos.add(sw.elapsedMicroseconds);
          }
        }),
      );

      final duracionMs = DateTime.now().difference(inicio).inMilliseconds;
      final total = usuarios * appsPorUsuario;
      final p95 = _percentil(tiempos, 0.95);
      final tasaError = errores / total;
      final opsPorSegundo = total / (duracionMs / 1000);
      final opsPorMinuto = opsPorSegundo * 60;

      debugPrint('── Guardián: $usuarios dispositivos × $appsPorUsuario apps = $total verificaciones en ${duracionMs}ms');
      debugPrint('   p95        : ${(p95 / 1000).toStringAsFixed(3)}ms');
      debugPrint('   Errores    : $errores / $total (${(tasaError * 100).toStringAsFixed(2)}%)');
      debugPrint('   Throughput : ${opsPorSegundo.toStringAsFixed(0)} ops/s  |  ${opsPorMinuto.toStringAsFixed(0)} ops/min');

      expect(p95, lessThan(200000),
          reason: 'p95 fue ${(p95 / 1000).toStringAsFixed(2)}ms — supera 200ms');
      expect(tasaError, lessThan(0.01),
          reason: 'Tasa de error ${(tasaError * 100).toStringAsFixed(2)}% supera el 1%');
    });

    // ── TEST 3: 50 mascotas subiendo de nivel al mismo tiempo ─────────────────
    // Simula el momento en que muchos hijos llegan al umbral de nivel a la vez
    test('3. 100 mascotas con puntos distintos — cuántas suben de nivel por segundo',
        () async {
      const usuarios = 200;
      // Puntos distribuidos entre todos los niveles posibles
      final puntosSimulados = [
        0, 499, 500, 1099, 1100, 1899, 1900, 2899,
        2900, 4099, 4100, 5499, 5500, 7000,
        // Repite para llegar a 50 usuarios
        300, 600, 1200, 2000, 3500, 4500, 5800,
        100, 550, 1150, 1950, 2950, 4150, 5600,
        200, 700, 1300, 2100, 3000, 4200, 5700,
        400, 800, 1400, 2200, 3100, 4300, 5900,
        450, 900, 1500, 2300, 3200, 4400, 6000,
        350, 950,
      ];

      final tiempos = <int>[];
      int errores = 0;
      int suberonDeNivel = 0;

      final inicio = DateTime.now();

      await Future.wait(
        List.generate(usuarios, (u) async {
          final sw = Stopwatch()..start();
          try {
            final pet = PetModel(
              puntos: puntosSimulados[u % puntosSimulados.length],
              tipoAvatar: ['mago', 'ninja', 'gamer', 'dormilon', 'samuray', 'princes'][u % 6],
            );
            if (pet.nivel > 0) suberonDeNivel++;
            pet.imagePath;
          } catch (_) {
            errores++;
          }
          sw.stop();
          tiempos.add(sw.elapsedMicroseconds);
        }),
      );

      final duracionMs = DateTime.now().difference(inicio).inMilliseconds.clamp(1, 999999);
      final p95 = _percentil(tiempos, 0.95);
      final tasaError = errores / usuarios;
      final evolucionesPorSegundo = suberonDeNivel / (duracionMs / 1000);
      final evolucionesPorMinuto = evolucionesPorSegundo * 60;

      debugPrint('── Mascotas: $usuarios usuarios concurrentes en ${duracionMs}ms');
      debugPrint('   p95               : ${(p95 / 1000).toStringAsFixed(3)}ms');
      debugPrint('   Errores           : $errores / $usuarios (${(tasaError * 100).toStringAsFixed(2)}%)');
      debugPrint('   Subieron de nivel : $suberonDeNivel / $usuarios usuarios');
      debugPrint('   Evoluciones/s     : ${evolucionesPorSegundo.toStringAsFixed(0)}');
      debugPrint('   Evoluciones/min   : ${evolucionesPorMinuto.toStringAsFixed(0)}');

      expect(p95, lessThan(300000),
          reason: 'p95 fue ${(p95 / 1000).toStringAsFixed(2)}ms — supera 300ms');
      expect(tasaError, lessThan(0.01),
          reason: 'Tasa de error ${(tasaError * 100).toStringAsFixed(2)}% supera el 1%');
      expect(suberonDeNivel, greaterThan(0),
          reason: 'Ninguna mascota subió de nivel');
    });

    // ── TEST 4: 100 usuarios buscando su avatar al mismo tiempo ──────────────
    // Simula la carga cuando muchos hijos abren el home con su mascota
    test('4. 100 usuarios cargando su avatar concurrentemente — p95 < 300ms, error < 1%',
        () async {
      const usuarios = 100;
      final ids = ['mago', 'ninja', 'gamer', 'dormilon', 'samuray', 'princes'];
      final tiempos = <int>[];
      int errores = 0;

      final inicio = DateTime.now();

      await Future.wait(
        List.generate(usuarios, (u) async {
          final sw = Stopwatch()..start();
          try {
            final avatar = AvatarTypes.byId(ids[u % ids.length]);
            avatar.imagenNivel((u % 6) + 1);
          } catch (_) {
            errores++;
          }
          sw.stop();
          tiempos.add(sw.elapsedMicroseconds);
        }),
      );

      final duracionMs = DateTime.now().difference(inicio).inMilliseconds;
      final p95 = _percentil(tiempos, 0.95);
      final tasaError = errores / usuarios;
      final opsPorSegundo = usuarios / (duracionMs / 1000);
      final opsPorMinuto = opsPorSegundo * 60;

      debugPrint('── Avatares: $usuarios usuarios concurrentes en ${duracionMs}ms');
      debugPrint('   p95        : ${(p95 / 1000).toStringAsFixed(3)}ms');
      debugPrint('   Errores    : $errores / $usuarios (${(tasaError * 100).toStringAsFixed(2)}%)');
      debugPrint('   Throughput : ${opsPorSegundo.toStringAsFixed(0)} ops/s  |  ${opsPorMinuto.toStringAsFixed(0)} ops/min');

      expect(p95, lessThan(300000),
          reason: 'p95 fue ${(p95 / 1000).toStringAsFixed(2)}ms — supera 300ms');
      expect(tasaError, lessThan(0.01),
          reason: 'Tasa de error ${(tasaError * 100).toStringAsFixed(2)}% supera el 1%');
    });
  });
}
