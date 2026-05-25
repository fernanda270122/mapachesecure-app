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

  // Tu lista de apps populares para mapeo visual
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

      _listaUsoReal = infos.where((info) {
        final milis = int.parse(info.totalTimeInForeground ?? '0');
        final package = info.packageName ?? '';
        return milis > 0 && !zonaSeguraYFantasmas.contains(package);
      }).toList();

      _listaUsoReal.sort((a, b) {
        final tA = int.parse(a.totalTimeInForeground ?? '0');
        final tB = int.parse(b.totalTimeInForeground ?? '0');
        return tB.compareTo(tA);
      });

      // 👇 NUEVO: Una vez que tenemos los datos locales del día, los mandamos a la API
      if (_listaUsoReal.isNotEmpty) {
        await sincronizarActividadConServidor();
      }
    } catch (e) {
      print("❌ Error cargando tiempos: $e");
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // 🚀 FUNCIÓN PARA SUBIR LOS DATOS AL BACKEND
  Future<void> sincronizarActividadConServidor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? idHijo = prefs.getString('hijo_id');
      final String? token = prefs.getString('auth_token');

      if (idHijo == null || token == null) return;

      final url = Uri.parse(
        'https://mapachesecure-backend.onrender.com/actividad/$idHijo',
      );

      // Mapeamos nuestra lista de UsageInfo a un JSON que entienda tu backend
      final List<Map<String, dynamic>> cuerpoJson = _listaUsoReal.map((app) {
        return {
          'package_name': app.packageName,
          'minutos_uso': Duration(
            milliseconds: int.parse(app.totalTimeInForeground ?? '0'),
          ).inMinutes,
        };
      }).toList();

      final respuesta = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'actividades': cuerpoJson}),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        print(
          "🛡️ Guardián: Actividad diaria sincronizada con el servidor con éxito.",
        );
      } else {
        print(
          "⚠️ Falló la sincronización de actividad: ${respuesta.statusCode}",
        );
      }
    } catch (e) {
      print("❌ Error de red al sincronizar actividad: $e");
    }
  }

  Duration get tiempoTotalPantalla {
    int totalMilis = 0;
    for (var info in _listaUsoReal) {
      totalMilis += int.parse(info.totalTimeInForeground ?? '0');
    }
    return Duration(milliseconds: totalMilis);
  }
}
