import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import '../../services/api_service.dart';

class ActividadHijoScreen extends StatefulWidget {
  final Map<dynamic, dynamic> hijo;

  const ActividadHijoScreen({super.key, required this.hijo});

  @override
  State<ActividadHijoScreen> createState() => _ActividadHijoScreenState();
}

class _ActividadHijoScreenState extends State<ActividadHijoScreen> {
  final ApiService _api = ApiService();
  bool _cargando = true;
  List<dynamic> _listaUso = [];
  int _minutosTotales = 0;

  @override
  void initState() {
    super.initState();
    _cargarActividadDelDia();
  }

  Future<void> _cargarActividadDelDia() async {
    final hijoId = widget.hijo['id'] ?? widget.hijo['hijo_id'];

    try {
      final respuesta = await _api.get('/actividad/$hijoId');

      if (respuesta is List) {
        int total = 0;
        for (var app in respuesta) {
          total += (app['minutos_uso'] as int? ?? 0);
        }

        if (!mounted) return;

        setState(() {
          _listaUso = respuesta;
          _minutosTotales = total;
          _cargando = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _cargando = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  String _formatDuration(int minutosTotales) {
    int horas = minutosTotales ~/ 60;
    int minutos = minutosTotales % 60;
    if (horas > 0) return '${horas}h ${minutos}m';
    return '$minutos min';
  }

  // Función extra para darle un aspecto más visual a las apps más comunes
  Map<String, dynamic> _obtenerInfoApp(
    String packageName,
    Color colorPorDefecto,
  ) {
    final lower = packageName.toLowerCase();

    // Mapeo manual de las más populares
    if (lower.contains('whatsapp')) {
      return {'nombre': 'WhatsApp', 'icon': Icons.chat, 'color': Colors.green};
    }
    if (lower.contains('facebook') || lower.contains('katana')) {
      return {
        'nombre': 'Facebook',
        'icon': Icons.facebook,
        'color': Colors.blue,
      };
    }
    if (lower.contains('instagram')) {
      return {
        'nombre': 'Instagram',
        'icon': Icons.camera_alt,
        'color': Colors.purple,
      };
    }
    if (lower.contains('youtube')) {
      return {
        'nombre': 'YouTube',
        'icon': Icons.play_circle_filled,
        'color': Colors.red,
      };
    }
    if (lower.contains('tiktok') || lower.contains('zhiliao')) {
      return {
        'nombre': 'TikTok',
        'icon': Icons.music_note,
        'color': Colors.black87,
      };
    }
    if (lower.contains('chrome')) {
      return {
        'nombre': 'Chrome',
        'icon': Icons.public,
        'color': Colors.blueAccent,
      };
    }
    if (lower.contains('discord')) {
      return {'nombre': 'Discord', 'icon': Icons.forum, 'color': Colors.indigo};
    }
    if (lower.contains('roblox')) {
      return {
        'nombre': 'Roblox',
        'icon': Icons.videogame_asset,
        'color': Colors.green,
      };
    }

    // Si es una app desconocida, sacamos un nombre presentable
    final partes = packageName.split('.');
    String fallbackName = partes.last.toUpperCase();

    // Si la última palabra es "ANDROID" o "APP", agarramos la palabra anterior para que tenga sentido
    if (fallbackName == 'ANDROID' ||
        fallbackName == 'APP' ||
        fallbackName == 'MOBILE') {
      if (partes.length > 1) {
        fallbackName = partes[partes.length - 2].toUpperCase();
      }
    }

    return {
      'nombre': fallbackName,
      'icon': Icons.android,
      'color': colorPorDefecto,
    };
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    final tiempoTotalStr = _formatDuration(_minutosTotales);
    const limitePermitidoHoras = 3;
    final porcentajeTotal = (_minutosTotales / (limitePermitidoHoras * 60))
        .clamp(0.0, 1.0);
    final nombreHijo = widget.hijo['nombre'] ?? 'tu hijo';

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Actividad de $nombreHijo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(temaPadre.primary, Colors.white, 0.62)!,
              temaPadre.background,
            ],
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargarActividadDelDia,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen de Hoy',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87, // CORREGIDO AQUÍ
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Tarjeta de tiempo total
                        _buildTotalTimeCard(
                          temaPadre.primary,
                          tiempoTotalStr,
                          porcentajeTotal,
                        ),

                        SizedBox(height: 30.h),

                        Text(
                          'Tiempo por Aplicación',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87, // CORREGIDO AQUÍ
                          ),
                        ),
                        SizedBox(height: 15.h),

                        _listaUso.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: Text(
                                  'No hay registros de actividad para hoy todavía.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _listaUso.length,
                                itemBuilder: (context, index) {
                                  // ... dentro del ListView.builder en actividad_hijo_screen.dart
                                  final appDb =
                                      _listaUso[index]; // Ajusta el nombre de la variable según tu código
                                  final String packageName =
                                      appDb['package_name'] ?? 'Desconocida';
                                  final int minutos = appDb['minutos_uso'] ?? 0;

                                  final double progresoApp = (minutos / 60)
                                      .clamp(0.0, 1.0);

                                  // Extraemos TODA la info: nombre, icono y color
                                  final appInfo = _obtenerInfoApp(
                                    packageName,
                                    temaPadre.primary,
                                  );

                                  return _buildAppUsageTile(
                                    appInfo['nombre'], // <-- AHORA USA EL NOMBRE REAL, YA NO EL SPLIT
                                    _formatDuration(minutos),
                                    appInfo['icon'],
                                    appInfo['color'],
                                    progresoApp,
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTotalTimeCard(
    Color primaryColor,
    String tiempoTotal,
    double porcentaje,
  ) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tiempo Total de Pantalla',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            tiempoTotal,
            style: TextStyle(
              fontSize: 38.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            'Supervisión remota activa',
            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
          ),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 12.h,
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageTile(
    String app,
    String time,
    IconData icon,
    Color colorIcono,
    double progress,
  ) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          backgroundColor: colorIcono.withValues(alpha: 0.1),
          radius: 20.r,
          child: Icon(icon, color: colorIcono, size: 20.r),
        ),
        title: Text(
          app,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(time, style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 6.h),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorIcono.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorIcono),
            ),
          ],
        ),
      ),
    );
  }
}
