import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/detalle_desafio_screen.dart';

class MisDesafiosScreen extends StatefulWidget {
  const MisDesafiosScreen({super.key});

  @override
  State<MisDesafiosScreen> createState() => _MisDesafiosScreenState();
}

class _MisDesafiosScreenState extends State<MisDesafiosScreen> {
  final FlutterTts _tts = FlutterTts();

  int _completadosCount = 0;
  int _pendientesCount = 0;
  int _puntosHoy = 0;
  List<dynamic> _desafiosActivos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _tts.setLanguage('es-MX');
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final hijoId = prefs.getString('user_id') ?? '';

    try {
      final api = ApiService();
      final desafiosData = await api.get('/desafios/');
      final completadosData = await api.get('/desafios/completados/$hijoId');
      final puntosData = await api.get('/desafios/puntos/$hijoId');

      setState(() {
        if (desafiosData is List) {
          // --- FILTRO CRÍTICO: Solo mostrar lo que el padre activó ---
          // Esto hace que si 'esta_activo' es false, el niño ni se entere que existe
          List<dynamic> listaFiltrada = desafiosData
              .where((d) => d['esta_activo'] == true)
              .toList();

          // --- ORDENAR POR TIPO (Usando la lista ya filtrada) ---
          listaFiltrada.sort((a, b) {
            String tipoA = (a['tipo'] ?? '').toString().toLowerCase();
            String tipoB = (b['tipo'] ?? '').toString().toLowerCase();
            return tipoA.compareTo(tipoB);
          });

          _desafiosActivos = listaFiltrada;
        }

        _completadosCount = completadosData is List
            ? completadosData.length
            : 0;
        _pendientesCount = _desafiosActivos.length;
        _puntosHoy = puntosData is Map ? (puntosData['total_puntos'] ?? 0) : 0;
        _cargando = false;
      });
    } catch (e) {
      print("Error cargando desafíos: $e");
      setState(() => _cargando = false);
    }
  }

  // --- CAMBIO 2: HELPERS ACTUALIZADOS PARA TUS TIPOS ---
  IconData _getIcono(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'cognitivo':
        return Icons.psychology;
      case 'fisico':
        return Icons.directions_run;
      case 'orden':
        return Icons.auto_awesome;
      default:
        return Icons.rocket_launch;
    }
  }

  Color _getColor(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'cognitivo':
        return Colors.blue;
      case 'fisico':
        return Colors.orange;
      case 'orden':
        return Colors.teal;
      default:
        return Colors.blueAccent;
    }
  }

  Color _getDificultadColor(String? dificultad) {
    switch (dificultad?.toLowerCase()) {
      case 'facil':
      case 'fácil':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'dificil':
      case 'difícil':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text(
          'Mis desafíos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                child: Column(
                  children: [
                    _buildProgresoHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Misiones activas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tema.onBackground,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _desafiosActivos.isEmpty
                          ? const Center(
                              child: Text("¡No tienes misiones pendientes! 🦝"),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _desafiosActivos.length,
                              itemBuilder: (context, index) {
                                final desafio = _desafiosActivos[index];

                                // --- NORMALIZACIÓN PARA ACOPLAR RAMAS ---
                                // Convertimos a minúsculas y si es 'cognitivo' lo tratamos como 'cognitiva'
                                String tipoRaw = (desafio['tipo'] ?? 'General')
                                    .toString()
                                    .toLowerCase();
                                if (tipoRaw == 'cognitivo')
                                  tipoRaw = 'cognitiva';
                                if (tipoRaw == 'fisico') tipoRaw = 'fisica';

                                final String tipoActual =
                                    tipoRaw; // Ahora tipoActual es consistente

                                // --- LÓGICA DE ENCABEZADOS POR SECCIÓN ---
                                bool mostrarEncabezado = false;
                                if (index == 0) {
                                  mostrarEncabezado = true;
                                } else {
                                  // También normalizamos el tipo anterior para comparar peras con peras
                                  String tipoAnterior =
                                      (_desafiosActivos[index - 1]['tipo'] ??
                                              '')
                                          .toString()
                                          .toLowerCase();
                                  if (tipoAnterior == 'cognitivo')
                                    tipoAnterior = 'cognitiva';
                                  if (tipoAnterior == 'fisico')
                                    tipoAnterior = 'fisica';

                                  if (tipoActual != tipoAnterior)
                                    mostrarEncabezado = true;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (mostrarEncabezado)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 15,
                                          bottom: 8,
                                          left: 5,
                                        ),
                                        child: Text(
                                          tipoActual
                                              .toUpperCase(), // Se verá siempre igual (ej: COGNITIVA)
                                          style: TextStyle(
                                            color: _getColor(tipoActual),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    _buildDesafioCard(
                                      context,
                                      desafio['titulo'] ?? 'Sin título',
                                      desafio['descripcion'] ??
                                          'Sin descripción',
                                      '${desafio['puntos']} pts',
                                      _getIcono(tipoActual),
                                      _getColor(tipoActual),
                                      desafio,
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Header separado para limpiar el build principal
  Widget _buildProgresoHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatWidget(
            label: 'Completados',
            value: '$_completadosCount',
            color: Colors.green,
          ),
          _StatWidget(
            label: 'Pendientes',
            value: '$_pendientesCount',
            color: Colors.orange,
          ),
          _StatWidget(
            label: 'Puntos hoy',
            value: '+$_puntosHoy',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDesafioCard(
    BuildContext context,
    String titulo,
    String subtitulo,
    String puntos,
    IconData icono,
    Color color,
    Map<String, dynamic> desafio,
  ) {
    // Extraemos la dificultad
    final String dificultad = desafio['dificultad'] ?? 'Normal';
    final Color dificultadColor = _getDificultadColor(dificultad);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Importante para que el badge no se salga
      child: Stack(
        children: [
          // CONTENIDO PRINCIPAL
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: 20,
              right: 15,
              top: 15, // Aumentamos un poco el top por el badge
              bottom: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icono, color: color),
            ),
            title: Padding(
              padding: const EdgeInsets.only(
                top: 5,
              ), // Espacio para no chocar con el badge
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(
              subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.indigo),
                  onPressed: () => _tts.speak(subtitulo),
                ),
                const SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      puntos,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            onTap: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleDesafioScreen(desafio: desafio),
                ),
              );
              if (resultado == true) _cargarDatos();
            },
          ),

          // BADGE DE DIFICULTAD
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: dificultadColor,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                dificultad.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ESTO VA AL FINAL DEL ARCHIVO (Después de la última llave } de la pantalla)
class _StatWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatWidget({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color, // Aquí ya no debería salir rojo
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
