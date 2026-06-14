import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class ActividadProvider with ChangeNotifier {
  List<UsageInfo> _listaUsoReal = [];
  bool _cargando = false;

  List<UsageInfo> get listaUsoReal => _listaUsoReal;
  bool get cargando => _cargando;

  final List<Map<String, dynamic>> appsPopulares = [
    {
      'nombre': 'TikTok',
      'package': 'com.zhiliaoapp.musically',
      'icono': Icons.music_video,
      'color': Colors.black,
    },
    {
      'nombre': 'YouTube',
      'package': 'com.google.android.youtube',
      'icono': Icons.play_circle_fill,
      'color': Colors.red,
    },
    {
      'nombre': 'Instagram',
      'package': 'com.instagram.android',
      'icono': Icons.camera_alt,
      'color': Colors.purple,
    },
    {
      'nombre': 'Roblox',
      'package': 'com.roblox.client',
      'icono': Icons.videogame_asset,
      'color': Colors.green,
    },
    {
      'nombre': 'WhatsApp',
      'package': 'com.whatsapp',
      'icono': Icons.chat,
      'color': Colors.teal,
    },
    {
      'nombre': 'Facebook',
      'package': 'com.facebook.katana',
      'icono': Icons.facebook,
      'color': Colors.blue,
    },
  ];

  Future<void> obtenerActividadDelDia() async {
    _cargando = true;
    notifyListeners();

    try {
      DateTime ahora = DateTime.now();
      DateTime inicioDia = DateTime(ahora.year, ahora.month, ahora.day);

      List<UsageInfo> infos = await UsageStats.queryUsageStats(
        inicioDia,
        ahora,
      );

      List<String> zonaSeguraYFantasmas = [
        'com.mapachesecure.mapachesecure_app',
        'com.sec.android.app.launcher',
        'com.android.launcher',
        'com.android.systemui',
      ];

      // 1. Filtrar las que tienen tiempo y no son del sistema
      var filtradas = infos.where((info) {
        final milis = int.parse(info.totalTimeInForeground ?? '0');
        final package = info.packageName ?? '';
        return milis > 0 && !zonaSeguraYFantasmas.contains(package);
      }).toList();

      // 2. AGRUPAR: Sumamos los tiempos de las apps duplicadas (ej. los dos bloques de Instagram)
      Map<String, int> mapaAgrupado = {};
      for (var info in filtradas) {
        final pkg = info.packageName!;
        final milis = int.parse(info.totalTimeInForeground ?? '0');
        if (mapaAgrupado.containsKey(pkg)) {
          mapaAgrupado[pkg] = mapaAgrupado[pkg]! + milis;
        } else {
          mapaAgrupado[pkg] = milis;
        }
      }

      // 3. Convertimos el mapa agrupado de vuelta a nuestra lista
      _listaUsoReal = mapaAgrupado.entries.map((entry) {
        return UsageInfo(
          packageName: entry.key,
          totalTimeInForeground: entry.value.toString(),
        );
      }).toList();

      // 4. Ordenamos de mayor a menor
      _listaUsoReal.sort((a, b) {
        final tA = int.parse(a.totalTimeInForeground ?? '0');
        final tB = int.parse(b.totalTimeInForeground ?? '0');
        return tB.compareTo(tA);
      });

      // 5. Sincronizamos con el servidor de forma segura
      if (_listaUsoReal.isNotEmpty) {
        await sincronizarActividadConServidor();
      }
    } catch (e) {
      debugPrint("❌ Error cargando tiempos: $e");
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> sincronizarActividadConServidor() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🛡️ CORRECCIÓN DE LLAVES: Buscamos tanto 'hijo_id' como 'user_id' por si acaso
      final String? idHijo =
          prefs.getString('hijo_id') ?? prefs.getString('user_id');
      final String? token =
          prefs.getString('auth_token') ?? prefs.getString('token');

      // 📝 LOG 4: Ver si las credenciales están vacías
      debugPrint(
        "🔑 [Sincronización] Credenciales extraídas -> idHijo: $idHijo | token: ${token != null ? 'Detectado' : 'NULL'}",
      );

      if (idHijo == null || token == null) {
        debugPrint(
          "🛑 [Sincronización] Error crítico: idHijo o token son NULL en SharedPreferences. Abortando envío.",
        );
        return;
      }

      final url = Uri.parse(
        'https://mapachesecure-backend.onrender.com/actividad/$idHijo',
      );
      debugPrint("🌐 [Sincronización] Conectando con el endpoint: $url");

      final List<Map<String, dynamic>> cuerpoJson = _listaUsoReal.map((app) {
        final milis = int.parse(app.totalTimeInForeground ?? '0');
        final minutosRedondeados = (milis / 60000).round();

        return {
          'package_name': app.packageName,
          'minutos_uso': minutosRedondeados,
        };
      }).toList();

      // 📝 LOG 5: Verificar qué JSON exacto se va a enviar
      debugPrint(
        "📦 [Sincronización] JSON estructurado para enviar: ${jsonEncode({'actividades': cuerpoJson})}",
      );

      final respuesta = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'actividades': cuerpoJson}),
      );

      // 📝 LOG 6: Respuesta definitiva de tu FastAPI en Render
      debugPrint("📡 [Servidor] Código de respuesta: ${respuesta.statusCode}");
      debugPrint("📡 [Servidor] Cuerpo de respuesta: ${respuesta.body}");

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        debugPrint(
          "🛡️ Guardián: Actividad diaria sincronizada con el servidor con éxito.",
        );
      } else {
        debugPrint(
          "⚠️ Falló la sincronización de actividad. Código: ${respuesta.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ [Sincronización] Error de red catastrófico: $e");
    }
  }

  Duration get tiempoTotalPantalla {
    int totalMinutos = 0;
    for (var info in _listaUsoReal) {
      final milis = int.parse(info.totalTimeInForeground ?? '0');
      // Sumamos los minutos ya redondeados, así el hijo muestra exactamente
      // la misma sumatoria matemática que verá el padre en su pantalla.
      totalMinutos += (milis / 60000).round();
    }
    return Duration(minutes: totalMinutos);
  }
}
