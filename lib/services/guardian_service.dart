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
      appsAfectadas: (json['package_names'] as String? ?? "").split(','),
    );
  }
}

Future<void> initializeGuardian() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mapache_channel',
    'Guardián MapacheSecure',
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
      initialNotificationTitle: 'MapacheSecure Activo',
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

    // DateTime.weekday: Lunes es 1, Domingo es 7.
    // Supabase: Lunes suele ser 0. Normalizamos:
    if (!regla.dias.contains(ahora.weekday)) return false;

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

      print(
        "🛡️ Guardián: Sincronizado (Instante: ${appsEnListaNegra.length}, Horarios: ${reglasProgramadas.length})",
      );
    } catch (e) {
      print("❌ Error de red en el Guardián: $e");
    }
  }

  // --- INICIO DEL SERVICIO ---
  await actualizarReglasDesdeAPI();

  // Sincronización de reglas cada minuto
  Timer.periodic(const Duration(minutes: 1), (timer) {
    actualizarReglasDesdeAPI();
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
      print("🛑 Guardian: Deteniendo servicio. Usuario: $userId, Rol: $rol");
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

        // 🟢 1. SALVOCONDUCTO (Zona Segura)
        // Agregamos todos los nombres posibles del Launcher de Samsung y Android base
        List<String> zonaSegura = [
          miPropiaApp, // Tu aplicación MapacheSecure
          "com.sec.android.app.launcher", // Samsung One UI Home (S23 Ultra)
          "com.google.android.apps.nexuslauncher", // Google Pixel Launcher
          "com.android.launcher", // Android Launcher base
          "com.android.systemui", // Interfaz de sistema (notificaciones/recientes)
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
            if (estaEnHorarioProhibido(regla)) {
              if (regla.appsAfectadas.contains(appActual)) {
                debeBloquear = true;
                break;
              }
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
