import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

      // 1. Obtener todos los desafíos disponibles (Pendientes)[cite: 1]
      final desafiosData = await api.get('/desafios/');

      // 2. Obtener desafíos ya completados para el contador[cite: 1]
      final completadosData = await api.get('/desafios/completados/$hijoId');

      // 3. Obtener puntos totales[cite: 1]
      final puntosData = await api.get('/desafios/puntos/$hijoId');

      setState(() {
        _desafiosActivos = desafiosData is List ? desafiosData : [];
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

  // Helpers para iconos y colores según el tipo del backend[cite: 1]
  IconData _getIcono(String? tipo) {
    switch (tipo) {
      case 'cognitiva':
        return Icons.calculate;
      case 'fisica':
        return Icons.fitness_center;
      case 'hogar':
        return Icons.bed;
      default:
        return Icons.rocket_launch;
    }
  }

  Color _getColor(String? tipo) {
    switch (tipo) {
      case 'cognitiva':
        return Colors.blue;
      case 'fisica':
        return Colors.orange;
      case 'hogar':
        return Colors.purple;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Mis desafíos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 148, 216),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: Column(
                children: [
                  // Cabecera de progreso con datos reales[cite: 1]
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
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
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Misiones activas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ),

                  // Lista dinámica de desafíos desde el backend[cite: 1]
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
                              return _buildDesafioCard(
                                context,
                                desafio['titulo'] ?? 'Sin título',
                                desafio['descripcion'] ?? 'Sin descripción',
                                '${desafio['puntos']} pts',
                                _getIcono(desafio['tipo']),
                                _getColor(desafio['tipo']),
                              );
                            },
                          ),
                  ),
                ],
              ),
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
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitulo),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.indigo),
              onPressed: () =>
                  _tts.speak(subtitulo), // Lee la instrucción completa[cite: 1]
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
        onTap: () {},
      ),
    );
  }
}

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
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
