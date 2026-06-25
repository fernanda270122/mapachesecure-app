import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // <-- MANTENIDO PARA LA ADAPTABILIDAD
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // <-- MANTENIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- MANTENIDO
import 'package:shared_preferences/shared_preferences.dart';

class CanjesPendientesScreen extends StatefulWidget {
  const CanjesPendientesScreen({super.key});
  static http.Client? testClient;

  @override
  State<CanjesPendientesScreen> createState() => _CanjesPendientesScreenState();
}

class _CanjesPendientesScreenState extends State<CanjesPendientesScreen> {
  List<dynamic> _canjes = [];
  bool _cargando = true;
  final String _base = 'https://mapachesecure-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _cargarCanjes();
  }

  Future<void> _cargarCanjes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final padreId = prefs.getString('user_id') ?? '';
      final client = CanjesPendientesScreen.testClient ?? http.Client();
      final res = await client.get(
        Uri.parse('$_base/canjes/pendientes/$padreId'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _canjes = jsonDecode(res.body);
        });
      }
    } catch (e) {
      // Manejo silencioso original
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _accion(String canjeId, String tipo) async {
    try {
      final client = CanjesPendientesScreen.testClient ?? http.Client();
      final res = await client.post(Uri.parse('$_base/canjes/$tipo/$canjeId'));
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud ${tipo}ada con éxito'),
            backgroundColor: tipo == 'aprobar' ? Colors.green : Colors.red,
          ),
        );
        _cargarCanjes();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al procesar acción')));
    }
  }

  String _genero(Map<String, dynamic> c) {
    final s = c['usuarios']?['sexo'] ?? 'otro';
    if (s == 'masculino') return 'Hijo';
    if (s == 'femenino') return 'Hija';
    return 'Menor';
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Canjes Pendientes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom:
            true, // 🛡️ Evita que choque con la barra inferior física de gestos
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  temaPadre.primary,
                  Colors.white,
                  0.62,
                )!, // <-- RESTAURADO TU TONO Y DEGRADADO
                temaPadre.background,
              ],
            ),
          ),
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _canjes.isEmpty
              ? Center(
                  child: Text(
                    'No hay canjes esperando aprobación',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: _canjes.length,
                  itemBuilder: (context, index) {
                    final c = _canjes[index];
                    final recompensa =
                        c['recompensas']?['nombre'] ?? 'Recompensa';
                    final puntos = c['recompensas']?['puntos_requeridos'] ?? 0;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: temaPadre.primary.withValues(
                            alpha: 0.1,
                          ),
                          radius: 22.r,
                          child: Icon(
                            Icons.card_giftcard,
                            color: temaPadre.primary,
                            size: 22.r,
                          ),
                        ),
                        title: Text(
                          '$recompensa ($puntos pts)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            '${_genero(c)}: ${c['usuarios']?['nombre'] ?? ''}',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28.r,
                              ),
                              onPressed: () => _accion(c['id'], 'aprobar'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            SizedBox(width: 8.w),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 28.r,
                              ),
                              onPressed: () => _accion(c['id'], 'rechazar'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
