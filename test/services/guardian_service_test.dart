import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/services/guardian_service.dart';

/// Un clon seguro que expone la lógica pura del Guardián sin levantar servicios de Android
class TestGuardianUtils {
  // Replicamos exactamente tu algoritmo de comparación horaria y desfase de días
  bool evaluarHorarioProhibido(ReglaBloqueo regla, DateTime momentoSimulado) {
    final int horaActualMin =
        momentoSimulado.hour * 60 + momentoSimulado.minute;

    int aMinutos(String s) {
      final partes = s.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    }

    final int inicioMin = aMinutos(regla.inicio);
    final int finMin = aMinutos(regla.fin);

    // Tu lógica: DateTime.weekday (Lunes=1, Domingo=7) -> Supabase (Lunes=0, Domingo=6)
    if (!regla.dias.contains(momentoSimulado.weekday - 1)) return false;

    return horaActualMin >= inicioMin && horaActualMin <= finMin;
  }

  // Replicamos la lógica de toma de decisiones del bucle de vigilancia de MapacheSecure
  bool evaluarSiDebeBloquear({
    required String appActual,
    required List<String> appsEnListaNegra,
    required List<ReglaBloqueo> reglasProgramadas,
    required DateTime momentoSimulado,
    required String miPropiaApp,
  }) {
    // 1. SALVOCONDUCTO (Zona Segura Completa)
    List<String> zonaSegura = [
      miPropiaApp,
      "com.sec.android.app.launcher",
      "com.google.android.apps.nexuslauncher",
      "com.android.launcher3",
      "com.miui.home",
    ];

    if (zonaSegura.contains(appActual)) return false;

    // 2. TRIPLE CANDADO (Seguridad Crítica)
    List<String> rutasPeligrosas = [
      "com.android.settings",
      "com.google.android.packageinstaller",
      "com.android.vending",
    ];

    if (rutasPeligrosas.contains(appActual)) return true;

    // 3. CHEQUEO DE LISTA NEGRA
    if (appsEnListaNegra.contains(appActual)) return true;

    // 4. CHEQUEO PROGRAMADO
    for (var regla in reglasProgramadas) {
      if (evaluarHorarioProhibido(regla, momentoSimulado) &&
          regla.appsAfectadas.contains(appActual)) {
        return true;
      }
    }

    return false;
  }
}

void main() {
  group('Pruebas unitarias para la lógica del Guardián Raccu', () {
    test(
      '1. ReglaBloqueo.fromJson debe parsear y decodificar los arreglos complejos de Supabase',
      () {
        final Map<String, dynamic> jsonSupabase = {
          'hora_inicio': '14:00',
          'hora_fin': '18:30',
          'dias_semana':
              '[0, 1, 2]', // String plano JSON de días (Lunes, Martes, Miércoles)
          'package_names':
              'com.instagram.android,com.zhiliaoapp.musically', // Apps separadas por comas
        };

        final regla = ReglaBloqueo.fromJson(jsonSupabase);

        expect(regla.inicio, '14:00');
        expect(regla.fin, '18:30');
        expect(regla.dias, containsAll([0, 1, 2]));
        expect(regla.appsAfectadas, contains('com.instagram.android'));
        expect(regla.appsAfectadas, contains('com.zhiliaoapp.musically'));
      },
    );

    test(
      '2. estaEnHorarioProhibido debe retornar TRUE si coincide el día y la hora está en el rango',
      () {
        final utils = TestGuardianUtils();
        final regla = ReglaBloqueo(
          inicio: '22:00',
          fin: '23:59',
          dias: [4], // 4 = Viernes en Supabase (5 - 1)
          appsAfectadas: ['com.android.vending'],
        );

        // Simulamos un Viernes a las 22:30 horas
        final viernesNoche = DateTime(
          2026,
          6,
          5,
          22,
          30,
        ); // 5 de Junio de 2026 es Viernes (weekday = 5)

        final resultado = utils.evaluarHorarioProhibido(regla, viernesNoche);
        expect(resultado, true);
      },
    );

    test(
      '3. estaEnHorarioProhibido debe retornar FALSE si el reloj está fuera de rango o es otro día',
      () {
        final utils = TestGuardianUtils();
        final regla = ReglaBloqueo(
          inicio: '08:00',
          fin: '12:00',
          dias: [0, 1, 2, 3, 4], // Lunes a Viernes
          appsAfectadas: [],
        );

        // Caso A: Mismo día, pero más temprano (07:15) - Cambiado a mananaTemprano
        final mananaTemprano = DateTime(2026, 6, 5, 7, 15); // Viernes
        expect(utils.evaluarHorarioProhibido(regla, mananaTemprano), false);

        // Caso B: Misma hora, pero día de fin de semana (Sábado) - Cambiado a sabadoManana
        final sabadoManana = DateTime(
          2026,
          6,
          6,
          10,
          0,
        ); // Sábado (weekday = 6)
        expect(utils.evaluarHorarioProhibido(regla, sabadoManana), false);
      },
    );

    test(
      '4. El Guardián debe respetar la Zona Segura (Salvoconducto) y no bloquear el Launcher o la propia App',
      () {
        final utils = TestGuardianUtils();

        // Intentamos forzar un bloqueo sobre el Launcher de Samsung
        final resultado = utils.evaluarSiDebeBloquear(
          appActual: 'com.sec.android.app.launcher',
          appsEnListaNegra: [
            'com.sec.android.app.launcher',
          ], // Aunque esté en lista negra por error
          reglasProgramadas: [],
          momentoSimulado: DateTime.now(),
          miPropiaApp: 'com.mapachesecure.mapachesecure_app',
        );

        expect(
          resultado,
          false,
        ); // Zona segura tiene prioridad total, no se bloquea
      },
    );

    test(
      '5. El Triple Candado debe gatillar bloqueo inmediato si se abren los Ajustes del sistema',
      () {
        final utils = TestGuardianUtils();

        final resultado = utils.evaluarSiDebeBloquear(
          appActual:
              'com.android.settings', // El niño intenta desinstalar la app
          appsEnListaNegra: [],
          reglasProgramadas: [],
          momentoSimulado: DateTime.now(),
          miPropiaApp: 'com.mapachesecure.mapachesecure_app',
        );

        expect(resultado, true); // Bloqueo preventivo exitoso
      },
    );

    test(
      '6. ReglaBloqueo constructor directo debe exponer sus propiedades correctamente',
      () {
        final regla = ReglaBloqueo(
          inicio: '09:00',
          fin: '17:00',
          dias: [0, 1, 2, 3, 4],
          appsAfectadas: ['com.instagram.android', 'com.tiktok.android'],
        );

        expect(regla.inicio, '09:00');
        expect(regla.fin, '17:00');
        expect(regla.dias.length, 5);
        expect(regla.appsAfectadas, contains('com.tiktok.android'));
      },
    );

    test(
      '7. ReglaBloqueo.fromJson con package_names null debe resultar en lista vacía',
      () {
        final json = {
          'hora_inicio': '08:00',
          'hora_fin': '20:00',
          'dias_semana': '[0]',
          'package_names': null,
        };

        final regla = ReglaBloqueo.fromJson(json);

        expect(regla.appsAfectadas, isEmpty);
      },
    );

    test(
      '8. ReglaBloqueo.fromJson con una sola app debe parsear correctamente',
      () {
        final json = {
          'hora_inicio': '15:00',
          'hora_fin': '22:00',
          'dias_semana': '[5, 6]',
          'package_names': 'com.whatsapp',
        };

        final regla = ReglaBloqueo.fromJson(json);

        expect(regla.appsAfectadas.length, 1);
        expect(regla.appsAfectadas.first, 'com.whatsapp');
        expect(regla.dias, containsAll([5, 6]));
      },
    );

    test(
      '9. estaEnHorarioProhibido debe retornar TRUE en el borde exacto de inicio',
      () {
        final utils = TestGuardianUtils();
        final regla = ReglaBloqueo(
          inicio: '10:00',
          fin: '12:00',
          dias: [0], // Lunes
          appsAfectadas: ['com.juego'],
        );

        // Lunes a las 10:00 exactas (borde de inicio)
        final lunes10 = DateTime(2026, 6, 15, 10, 0); // 15 jun 2026 = Lunes
        expect(utils.evaluarHorarioProhibido(regla, lunes10), true);
      },
    );

    test(
      '10. estaEnHorarioProhibido debe retornar TRUE en el borde exacto de fin',
      () {
        final utils = TestGuardianUtils();
        final regla = ReglaBloqueo(
          inicio: '10:00',
          fin: '12:00',
          dias: [0], // Lunes
          appsAfectadas: ['com.juego'],
        );

        // Lunes a las 12:00 exactas (borde de fin)
        final lunes12 = DateTime(2026, 6, 15, 12, 0);
        expect(utils.evaluarHorarioProhibido(regla, lunes12), true);
      },
    );

    test(
      '11. App en lista negra que no está en zona segura debe bloquearse',
      () {
        final utils = TestGuardianUtils();

        final resultado = utils.evaluarSiDebeBloquear(
          appActual: 'com.roblox.client',
          appsEnListaNegra: ['com.roblox.client'],
          reglasProgramadas: [],
          momentoSimulado: DateTime.now(),
          miPropiaApp: 'com.mapachesecure.mapachesecure_app',
        );

        expect(resultado, true);
      },
    );

    test(
      '12. App no listada en ninguna regla ni lista negra no debe bloquearse',
      () {
        final utils = TestGuardianUtils();

        final resultado = utils.evaluarSiDebeBloquear(
          appActual: 'com.app.segura',
          appsEnListaNegra: ['com.roblox.client'],
          reglasProgramadas: [],
          momentoSimulado: DateTime.now(),
          miPropiaApp: 'com.mapachesecure.mapachesecure_app',
        );

        expect(resultado, false);
      },
    );

    test(
      '13. App incluida en una regla de horario activa debe bloquearse',
      () {
        final utils = TestGuardianUtils();
        // Regla activa un Lunes de 00:00 a 23:59
        final regla = ReglaBloqueo(
          inicio: '00:00',
          fin: '23:59',
          dias: [0], // Lunes (weekday=1 → weekday-1=0)
          appsAfectadas: ['com.juego.peligroso'],
        );

        final lunes = DateTime(2026, 6, 15, 14, 0); // Lunes a las 14:00

        final resultado = utils.evaluarSiDebeBloquear(
          appActual: 'com.juego.peligroso',
          appsEnListaNegra: [],
          reglasProgramadas: [regla],
          momentoSimulado: lunes,
          miPropiaApp: 'com.mapachesecure.mapachesecure_app',
        );

        expect(resultado, true);
      },
    );
  });
}
