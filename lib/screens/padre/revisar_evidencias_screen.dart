import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/services/api_service.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    // Escucha el tema exclusivo del padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Revisar Evidencias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary, // <-- APPBAR DINÁMICO
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
            : _evidencias.isEmpty
            ? const Center(
                child: Text(
                  "No hay evidencias pendientes por ahora 👏",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ), // <-- COLOR AJUSTADO
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _evidencias.length,
                itemBuilder: (context, index) {
                  final item = _evidencias[index];
                  return _buildEvidenciaCard(
                    item,
                    temaPadre.primary,
                  ); // <-- PASADO EL COLOR DINÁMICO
                },
              ),
      ),
    );
  }

  Widget _buildEvidenciaCard(dynamic item, Color colorTema) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorTema.withOpacity(
                0.1,
              ), // <-- MATIZ DEL COLOR DEL PADRE
              child: Icon(
                Icons.history_edu,
                color: colorTema,
              ), // <-- ÍCONO DINÁMICO
            ),
            title: Text(
              item['titulo'] ?? 'Desafío Sin Nombre',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Hijo: ${item['hijo_nombre']}",
              style: const TextStyle(color: Colors.black54),
            ),
          ),

          if (item['url_evidencia'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Un toque más estilizado para las fotos
                child: Image.network(
                  item['url_evidencia'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _procesarEvidencia(item['id'], false),
                  icon: const Icon(Icons.close),
                  label: const Text(
                    "Rechazar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _procesarEvidencia(item['id'], true),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    "Aprobar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
