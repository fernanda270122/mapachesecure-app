// coverage:ignore-file
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:bg_launcher/bg_launcher.dart';

// 1. Modelo para procesar los horarios de Supabase
class ReglaBloqueo {
  final String inicio;
  final String fin;
  final List<int> dias;
  final List<String> appsAfectadas;

  ReglaBloqueo({
    required this.inicio,
    required this.fin,
    required this.dias,
    required this.appsAfectadas,
  });

  factory ReglaBloqueo.fromJson(Map<String, dynamic> json) {
    return ReglaBloqueo(
      inicio: json['hora_inicio'],
      fin: json['hora_fin'],
      // Decodificamos la lista de días [0,1,2...] que viene de Supabase
      dias: List<int>.from(jsonDecode(json['dias_semana'])),
      appsAfectadas: (json['package_names'] as String? ?? "")
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

Future<void> initializeGuardian() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mapache_channel',
    'Guardián Raccu',
    description: 'Vigilando aplicaciones en segundo plano',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'mapache_channel',
      initialNotificationTitle: 'Raccu Activo',
      initialNotificationContent: 'Protegiendo tu dispositivo',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
    debugPrint("🛡️ Guardián: Servicio detenido por el usuario");
  });

  final String miPropiaApp = 'com.mapachesecure.mapachesecure_app';

  // --- NOTIFICACIONES DE HORARIO ---
  final FlutterLocalNotificationsPlugin notifHorario =
      FlutterLocalNotificationsPlugin();

  await notifHorario.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  const AndroidNotificationChannel horarioChannel = AndroidNotificationChannel(
    'horario_channel',
    'Notificaciones de Bloqueo',
    description: 'Avisa cuando inicia o termina un bloqueo programado',
    importance: Importance.high,
  );

  await notifHorario
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(horarioChannel);

  // Conjunto de claves de reglas activas en el último chequeo
  Set<String> reglasActivasPrevias = {};

  String claveRegla(ReglaBloqueo r) =>
      '${r.inicio}_${r.fin}_${r.dias.join('-')}';

  Set<String> reglasActivasAhora(
    List<ReglaBloqueo> reglas,
    bool Function(ReglaBloqueo) estaActiva,
  ) {
    return reglas.where(estaActiva).map(claveRegla).toSet();
  }

  Future<void> notificarCambioHorario(
    bool iniciando,
    ReglaBloqueo regla,
  ) async {
    await notifHorario.show(
      id: iniciando ? 300 : 301,
      title: iniciando
          ? '⏰ Bloqueo de horario iniciado'
          : '✅ Bloqueo de horario terminado',
      body: iniciando
          ? 'Las apps están restringidas hasta las ${regla.fin}'
          : 'Las apps están disponibles nuevamente (desde las ${regla.fin})',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'horario_channel',
          'Notificaciones de Bloqueo',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // --- MEMORIA DEL SERVICIO ---
  List<String> appsEnListaNegra = []; // Bloqueos instantáneos
  List<ReglaBloqueo> reglasProgramadas = []; // Bloqueos por horario

  // 2. FUNCIÓN PARA COMPARAR EL RELOJ
  bool estaEnHorarioProhibido(ReglaBloqueo regla) {
    final ahora = DateTime.now();
    final int horaActualMin = ahora.hour * 60 + ahora.minute;

    int aMinutos(String s) {
      final partes = s.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    }

    final int inicioMin = aMinutos(regla.inicio);
    final int finMin = aMinutos(regla.fin);

    // DateTime.weekday: Lunes=1, Domingo=7. Supabase: Lunes=0, Domingo=6.
    if (!regla.dias.contains(ahora.weekday - 1)) return false;

    return horaActualMin >= inicioMin && horaActualMin <= finMin;
  }

  Future<void> actualizarReglasDesdeAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? idHijo = prefs.getString('hijo_id');
      final String? token = prefs.getString('auth_token');

      if (idHijo == null || token == null) return;

      // A. Traer Bloqueos Instantáneos (Lista Negra)
      final urlInstante = Uri.parse(
        'https://mapachesecure-backend.onrender.com/bloqueos/$idHijo/apps-instante',
      );
      final respInstante = await http.get(
        urlInstante,
        headers: {'Authorization': 'Bearer $token'},
      );

      // B. Traer Bloqueos Programados (Horarios)
      final urlHorarios = Uri.parse(
        'https://mapachesecure-backend.onrender.com/bloqueos/$idHijo',
      );
      final respHorarios = await http.get(
        urlHorarios,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (respInstante.statusCode == 200) {
        final List<dynamic> data = jsonDecode(respInstante.body);
        appsEnListaNegra = data.map((e) => e.toString()).toList();
      }

      if (respHorarios.statusCode == 200) {
        final List<dynamic> data = jsonDecode(respHorarios.body);
        reglasProgramadas = data
            .map((json) => ReglaBloqueo.fromJson(json))
            .toList();
      }

      debugPrint(
        "🛡️ Guardián: Sincronizado (Instante: ${appsEnListaNegra.length}, Horarios: ${reglasProgramadas.length})",
      );
    } catch (e) {
      debugPrint("❌ Error de red en el Guardián: $e");
    }
  }

  // --- INICIO DEL SERVICIO ---
  await actualizarReglasDesdeAPI();
  // Guardamos el estado inicial sin notificar (la app acaba de arrancar)
  reglasActivasPrevias = reglasActivasAhora(
    reglasProgramadas,
    estaEnHorarioProhibido,
  );

  // Sincronización de reglas cada minuto + detección de inicio/fin de bloqueo
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    await actualizarReglasDesdeAPI();

    final reglasActuales = reglasActivasAhora(
      reglasProgramadas,
      estaEnHorarioProhibido,
    );

    for (final regla in reglasProgramadas) {
      final clave = claveRegla(regla);
      final eraActiva = reglasActivasPrevias.contains(clave);
      final esActiva = reglasActuales.contains(clave);

      if (!eraActiva && esActiva) {
        // La regla acaba de activarse
        await notificarCambioHorario(true, regla);
      } else if (eraActiva && !esActiva) {
        // La regla acaba de desactivarse
        await notificarCambioHorario(false, regla);
      }
    }

    reglasActivasPrevias = reglasActuales;
  });

  // Bucle de vigilancia cada 2 segundos (puedes bajarlo a 1 si prefieres)
  Timer.periodic(const Duration(milliseconds: 500), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthService(); // Usamos tu servicio existente

    // 🛡️ VALIDACIÓN MAESTRA
    final String? userId = prefs.getString('user_id');
    final String? rol = await auth
        .getRol(); // Obtenemos el rol desde tu lógica de Auth

    // Si no hay ID o el rol NO es hijo, el servicio se detiene físicamente
    if (userId == null || userId.isEmpty || rol != 'hijo') {
      debugPrint(
        "🛑 Guardian: Deteniendo servicio. Usuario: $userId, Rol: $rol",
      );
      timer.cancel();
      service.stopSelf();
      return;
    }
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(minutes: 1));

    List<EventUsageInfo> events = await UsageStats.queryEvents(
      startDate,
      endDate,
    );

    if (events.isNotEmpty) {
      var ultimosEventos = events.where((e) => e.eventType == '1').toList();

      if (ultimosEventos.isNotEmpty) {
        String appActual = ultimosEventos.last.packageName ?? '';

        // 🟢 1. SALVOCONDUCTO (Zona Segura Completa)
        List<String> zonaSegura = [
          miPropiaApp, // Tu aplicación MapacheSecure
          // Samsung
          "com.sec.android.app.launcher",
          "com.samsung.android.app.spage",

          // Google / Pixel
          "com.google.android.apps.nexuslauncher",
          "com.google.android.launcher",

          // AOSP base (Nuvia, Android Go, genéricos)
          "com.android.launcher",
          "com.android.launcher2",
          "com.android.launcher3",
          "com.android.launcher4",

          // Sistema Android
          "com.android.systemui",

          // Xiaomi / Redmi / POCO — MIUI y HyperOS
          "com.miui.home",
          "com.miui.msa.global",

          // Motorola
          "com.motorola.launcher3",

          // Huawei / Honor
          "com.huawei.android.launcher",
          "com.honor.android.launcher",

          // OPPO / Realme / OnePlus
          "com.coloros.launcher",
          "com.realme.launcher",
          "com.oneplus.launcher",

          // Vivo
          "com.bbk.launcher2",
          "com.vivo.launcher",

          // LG
          "com.lge.launcher3",

          // ZTE / Nuvia
          "com.zte.launcher",
          "com.nuvia.launcher",
        ];

        // Si el niño está en el inicio o en tu app, no evaluamos nada más
        if (zonaSegura.contains(appActual)) return;

        bool debeBloquear = false;

        // 🛡️ 2. TRIPLE CANDADO (Seguridad Crítica)
        // Esto evita desinstalación y forzar cierre
        List<String> rutasPeligrosas = [
          "com.android.settings", // Ajustes
          "com.google.android.packageinstaller", // Desinstalador
          "com.android.vending", // Play Store
        ];

        if (rutasPeligrosas.contains(appActual)) {
          debeBloquear = true;
        }

        // 🚫 3. CHEQUEO DE LISTA NEGRA (Apps bloqueadas siempre)
        if (!debeBloquear && appsEnListaNegra.contains(appActual)) {
          debeBloquear = true;
        }

        // ⏰ 4. CHEQUEO PROGRAMADO (Apps por horario)
        if (!debeBloquear) {
          for (var regla in reglasProgramadas) {
            if (estaEnHorarioProhibido(regla) &&
                regla.appsAfectadas.contains(appActual)) {
              debeBloquear = true;
              break;
            }
          }
        }

        // 🚀 EJECUCIÓN DEL BLOQUEO
        if (debeBloquear) {
          BgLauncher.bringAppToForeground();
          service.invoke('mostrarBloqueo', {'app': appActual});
        }
      }
    }
  });
}
