import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO
import 'package:shared_preferences/shared_preferences.dart';

class CanjesPendientesScreen extends StatefulWidget {
  const CanjesPendientesScreen({super.key});

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
      final res = await http.get(
        Uri.parse('$_base/canjes/pendientes/$padreId'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _canjes = jsonDecode(res.body);
        });
      } else {
        debugPrint('Error canjes: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Excepción canjes: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _accion(String canjeId, String tipo) async {
    await http.post(Uri.parse('$_base/canjes/$tipo/$canjeId'));
    _cargarCanjes();
  }

  String _genero(Map c) =>
      c['usuarios']?['sexo'] == 'femenino' ? 'Hija' : 'Hijo';
      
  @override
  Widget build(BuildContext context) {
    // Escucha el tema exclusivo del padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Canjes pendientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary, // <-- APPBAR REACTIVO
        foregroundColor: Colors.white,
      ),
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
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _canjes.isEmpty
            ? const Center(
                child: Text(
                  'No hay canjes pendientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _canjes.length,
                itemBuilder: (context, i) {
                  final c = _canjes[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        c['recompensas']?['titulo'] ?? 'Sin título',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Hijo: ${c['usuarios']?['nombre'] ?? ''}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ), // Íconos sutilmente más estilizados
                            onPressed: () => _accion(c['id'], 'aprobar'),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 28,
                            ),
                            onPressed: () => _accion(c['id'], 'rechazar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
