import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO
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
        title: const Text(
          'Gestionar Desafíos',
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
            : _hijos.isEmpty
            ? const Center(
                child: Text(
                  'No tienes hijos registrados',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Selecciona un hijo para ver sus desafíos',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ), // <-- COLOR AJUSTADO
                  ),
                  const SizedBox(height: 16),
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
    );
  }

  Widget _buildTarjetaHijo(Map<dynamic, dynamic> hijo, Color colorTema) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorTema.withOpacity(
            0.1,
          ), // <-- MATIZ DEL COLOR DEL PADRE
          child: Icon(Icons.child_care, color: colorTema), // <-- ÍCONO DINÁMICO
        ),
        title: Text(
          hijo['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text(
          'Toca para ver sus desafíos',
          style: TextStyle(color: Colors.black54),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorTema,
        ), // <-- FLECHA DINÁMICA
      ),
    );
  }
}
