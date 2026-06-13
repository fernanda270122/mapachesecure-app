import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'actividad_hijo_screen.dart';

class SeleccionarHijoActividadScreen extends StatefulWidget {
  const SeleccionarHijoActividadScreen({super.key});

  @override
  State<SeleccionarHijoActividadScreen> createState() =>
      _SeleccionarHijoActividadScreenState();
}

class _SeleccionarHijoActividadScreenState
    extends State<SeleccionarHijoActividadScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _hijos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHijos();
  }

  Future<void> _cargarHijos() async {
    final prefs = await SharedPreferences.getInstance();
    final padreId = prefs.getString('user_id') ?? '';
    try {
      final hijos = await _api.get('/usuarios/$padreId/hijos');

      if (!mounted) return;

      setState(() {
        _hijos = hijos is List ? hijos : [];
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Actividad de Pantalla',
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
              : _hijos.isEmpty
              ? Center(
                  child: Text(
                    'No tienes hijos registrados',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(20.r),
                  children: [
                    Text(
                      'Selecciona un hijo para revisar su uso de aplicaciones',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ..._hijos.map(
                      (hijo) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActividadHijoScreen(hijo: hijo),
                          ),
                        ).then((_) => _cargarHijos()),
                        child: _buildTarjetaHijo(hijo, temaPadre.primary),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTarjetaHijo(Map<dynamic, dynamic> hijo, Color colorTema) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          backgroundColor: colorTema.withOpacity(0.1),
          radius: 20.r,
          child: Icon(Icons.analytics_outlined, color: colorTema, size: 20.r),
        ),
        title: Text(
          hijo['nombre'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          'Toca para ver el reporte de hoy',
          style: TextStyle(color: Colors.black54, fontSize: 13.sp),
        ),
        trailing: Icon(Icons.chevron_right, color: colorTema, size: 24.r),
      ),
    );
  }
}
