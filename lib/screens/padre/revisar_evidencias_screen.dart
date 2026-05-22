import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
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
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al procesar")));
    }
  }

  // 🎨 DIÁLOGO DE CONFIRMACIÓN ADAPTATIVO CON FONDO LILA PASTEL Y TEXTOS NEGROS
  void _mostrarConfirmacionDialog({
    required String desafioId,
    required bool aprobado,
    required String tituloDesafio,
    required Color colorPrimario,
  }) {
    // Generamos matemáticamente el color lila suave de fondo usando el primario
    final colorFondoLilaSuave = Color.lerp(colorPrimario, Colors.white, 0.88)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorPrimario.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          backgroundColor: colorFondoLilaSuave,
          title: Text(
            aprobado ? '¿Aprobar Evidencia?' : '¿Rechazar Evidencia?',
            style: const TextStyle(
              color: Colors.black, // Título totalmente negro
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            aprobado
                ? '¿Estás seguro de que deseas aprobar el desafío "$tituloDesafio"? El niño recibirá sus puntos correspondientes.'
                : '¿Estás seguro de que deseas rechazar la evidencia de "$tituloDesafio"? Se le notificará al niño para que vuelva a intentarlo.',
            style: TextStyle(
              color: colorPrimario.withOpacity(
                0.9,
              ), // Texto adaptativo oscuro legible
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Cierra el alert primero
                _procesarEvidencia(desafioId, aprobado); // Ejecuta la acción
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: aprobado ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                aprobado ? 'Sí, Aprobar' : 'Sí, Rechazar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _evidencias.length,
                itemBuilder: (context, index) {
                  final item = _evidencias[index];
                  return _buildEvidenciaCard(item, temaPadre.primary);
                },
              ),
      ),
    );
  }

  Widget _buildEvidenciaCard(dynamic item, Color colorTema) {
    final String tituloDesafio = item['titulo'] ?? 'Desafío Sin Nombre';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorTema.withOpacity(0.1),
              child: Icon(Icons.history_edu, color: colorTema),
            ),
            title: Text(
              tituloDesafio,
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
                borderRadius: BorderRadius.circular(12),
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
                  // 🚀 LLAMADA A LA ALERTA AL TOCAR RECHAZAR
                  onPressed: () => _mostrarConfirmacionDialog(
                    desafioId: item['id'].toString(),
                    aprobado: false,
                    tituloDesafio: tituloDesafio,
                    colorPrimario: colorTema,
                  ),
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
                  // 🚀 LLAMADA A LA ALERTA AL TOCAR APROBAR
                  onPressed: () => _mostrarConfirmacionDialog(
                    desafioId: item['id'].toString(),
                    aprobado: true,
                    tituloDesafio: tituloDesafio,
                    colorPrimario: colorTema,
                  ),
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
