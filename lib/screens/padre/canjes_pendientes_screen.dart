import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      final res = await http.get(Uri.parse('$_base/canjes/pendientes/$padreId'));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Canjes pendientes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _canjes.isEmpty
              ? const Center(child: Text('No hay canjes pendientes'))
              : ListView.builder(
                  itemCount: _canjes.length,
                  itemBuilder: (context, i) {
                    final c = _canjes[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(c['recompensas']?['titulo'] ?? 'Sin título'),
                        subtitle: Text('${_genero(c)}: ${c['usuarios']?['nombre'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _accion(c['id'], 'aprobar'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _accion(c['id'], 'rechazar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}