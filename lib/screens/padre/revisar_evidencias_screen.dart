import 'package:flutter/material.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevisarEvidenciasScreen extends StatefulWidget {
  const RevisarEvidenciasScreen({super.key});

  @override
  State<RevisarEvidenciasScreen> createState() =>
      _RevisarEvidenciasScreenState();
}

class _RevisarEvidenciasScreenState extends State<RevisarEvidenciasScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _evidencias = [];
  bool _cargando = true;
  String _padreId = '';

  @override
  void initState() {
    super.initState();
    _fetchEvidencias();
  }

  Future<void> _fetchEvidencias() async {
    final prefs = await SharedPreferences.getInstance();
    _padreId = prefs.getString('user_id') ?? '';
    try {
      final res = await _api.get('/desafios/pendientes/$_padreId');
      print('respuesta backend: $res');
      setState(() {
        _evidencias = res is List ? res : [];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _procesarEvidencia(String desafioId, bool aprobado) async {
    try {
      await _api.put('/desafios/validar/$desafioId?aprobado=$aprobado', {});
      _fetchEvidencias();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al procesar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Revisar Evidencias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppBackground(child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _evidencias.isEmpty
          ? const Center(
              child: Text("No hay evidencias pendientes por ahora 👏", style: TextStyle(color: Colors.white) ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _evidencias.length,
              itemBuilder: (context, index) {
                final item = _evidencias[index];
                return _buildEvidenciaCard(item);
              },
            ),
      ),
    );
  }

  Widget _buildEvidenciaCard(dynamic item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.history_edu)),
            title: Text(
              item['titulo'] ?? 'Desafío Sin Nombre',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Hijo: ${item['hijo_nombre']}"),
          ),

          if (item['url_evidencia'] != null)
            Image.network(
              item['url_evidencia'],
              height: 200,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _procesarEvidencia(item['id'], false),
                  icon: const Icon(Icons.close),
                  label: const Text("Rechazar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _procesarEvidencia(item['id'], true),
                  icon: const Icon(Icons.check),
                  label: const Text("Aprobar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
