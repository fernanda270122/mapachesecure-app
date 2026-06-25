import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // <-- AÑADIDO PARA LA RESPONSIVIDAD
import 'package:provider/provider.dart'; // <-- MANTENIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- MANTENIDO
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'desafios_hijo_screen.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
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
      setState(() {
        _hijos = hijos is List ? hijos : [];
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el tema exclusivo del padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Gestionar Desafíos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ), // <-- RESPONSIVO
        ),
        backgroundColor: temaPadre.primary, // <-- APPBAR REACTIVO
        foregroundColor: Colors.white,
      ),
      // 🎨 EL CONTAINER POR FUERA: El degradado fluye completo detrás de toda la pantalla
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Tu degradado insignia al 0.62 para armonizar el fondo
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
        // 🛡️ EL SAFEAREA POR DENTRO: Evita el choque con la barra inferior física de navegación
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
                      fontSize: 16.sp, // <-- RESPONSIVO
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(20.r), // <-- RESPONSIVO
                  children: [
                    Text(
                      'Selecciona un hijo para ver sus desafíos',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15.sp, // <-- RESPONSIVO
                        fontWeight: FontWeight.w500,
                      ), // <-- COLOR AJUSTADO
                    ),
                    SizedBox(height: 16.h), // <-- RESPONSIVO
                    ..._hijos.map(
                      (hijo) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DesafiosHijoScreen(hijo: hijo),
                          ),
                        ).then((_) => _cargarHijos()),
                        child: _buildTarjetaHijo(
                          hijo,
                          temaPadre.primary,
                        ), // <-- PASADO EL COLOR DINÁMICO
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
      margin: EdgeInsets.only(bottom: 12.h), // <-- RESPONSIVO
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ), // <-- RESPONSIVO
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 4.h,
        ), // <-- RESPONSIVO
        leading: CircleAvatar(
          backgroundColor: colorTema.withValues(
            alpha: 0.1,
          ), // <-- MATIZ DEL COLOR DEL PADRE
          radius: 20.r, // <-- RESPONSIVO
          child: Icon(
            Icons.child_care,
            color: colorTema,
            size: 20.r, // <-- RESPONSIVO
          ), // <-- ÍCONO DINÁMICO
        ),
        title: Text(
          hijo['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ), // <-- RESPONSIVO
        ),
        subtitle: Text(
          'Toca para ver sus desafíos',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13.sp,
          ), // <-- RESPONSIVO
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorTema,
          size: 24.r, // <-- RESPONSIVO
        ), // <-- FLECHA DINÁMICA
      ),
    );
  }
}
