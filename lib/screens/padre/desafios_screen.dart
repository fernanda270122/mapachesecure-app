import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gestionar Desafíos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _hijos.isEmpty
                ? const Center(
                    child: Text(
                      'No tienes hijos registrados',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Selecciona un hijo/a para ver sus desafíos',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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
                          child: _buildTarjetaHijo(hijo),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTarjetaHijo(Map<dynamic, dynamic> hijo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: const Icon(Icons.child_care, color: AppColors.primary),
        ),
        title: Text(
          hijo['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Toca para ver sus desafíos'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
      ),
    );
  }
}