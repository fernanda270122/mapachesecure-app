import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/screens/hijo/detalle_desafio_screen.dart';
import 'package:mapachesecure_app/screens/hijo/tienda_recompensa_hijo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/hijo/guia_hijo_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mapachesecure_app/models/pet_model.dart';
import 'package:mapachesecure_app/screens/hijo/video_evolucion_screen.dart';


class HomeHijoScreen extends StatefulWidget {
  const HomeHijoScreen({super.key});

  @override
  State<HomeHijoScreen> createState() => _HomeHijoScreenState();
}

class _HomeHijoScreenState extends State<HomeHijoScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  String _nombre = '';
  int _puntos = 0;
  List<dynamic> _desafios = [];
  bool _cargando = true;
  Set<String> _pendientes = {};
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _nivelMascotaVisto = -1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _tts.setLanguage('es-MX');
    _activarGuardian();
    FlutterBackgroundService().startService();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _cargarNivelVisto();
  }
  @override
    void dispose() {
      _floatController.dispose();
      super.dispose();
    }
  Future<void> _cargarNivelVisto() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _nivelMascotaVisto = prefs.getInt('nivel_mascota_visto') ?? -1);
    }

  Future<void> _verificarEvolucion(int puntos) async {
    final nivel = _calcularNivel(puntos)['nivel'] as int;
    if (nivel >= 1 && _nivelMascotaVisto < 1) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('nivel_mascota_visto', nivel);
      setState(() => _nivelMascotaVisto = nivel);
      if (mounted) {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const VideoEvolucionScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    }
  }
  Future<void> _activarGuardian() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Explorador';
    final hijoId = prefs.getString('user_id') ?? '';

    try {
      final api = ApiService();
      final puntosData = await api.get('/desafios/puntos/$hijoId');
      final desafiosData = await api.get('/desafios/');
      final completadosData = await api.get('/desafios/completados/$hijoId');
      final nuevoPuntos = puntosData is Map ? (puntosData['total_puntos'] ?? 0) : 0;

      setState(() {
        if (completadosData is List) {
            _pendientes = completadosData
            
                .where((c) => c['validado'] == false)
                .map<String>((c) => c['desafio_id'].toString())
                .toSet();
                print('pendientes: $_pendientes');
          }
        _nombre = nombre;
        _puntos = nuevoPuntos;

        if (desafiosData is List) {
          // --- PASO 1: FILTRAR POR ESTADO ACTIVO
          // Primero nos quedamos solo con lo que el padre aprobó
          var listaFiltrada = desafiosData
              .where((d) => d['esta_activo'] == true)
              .toList();

          // --- PASO 2: FILTRAR REPETIDOS ---
          // Sobre la lista ya aprobada, quitamos duplicados por título
          final nombresVistos = <String>{};
          var listaLimpia = listaFiltrada
              .where((d) => nombresVistos.add(d['titulo'] ?? ''))
              .toList();

          var pendientesList = listaLimpia
              .where((d) => _pendientes.contains(d['id'].toString()))
              .toList();
          var disponibles = listaLimpia
              .where((d) => !_pendientes.contains(d['id'].toString()))
              .toList();
          disponibles.shuffle();
          _desafios = [...pendientesList, ...disponibles].take(3).toList();
        } else {
          _desafios = [];
        }
        _cargando = false;
      });
      await _verificarEvolucion(nuevoPuntos);
    } catch (e) {
      print("Error en Home: $e");

      // 🛡️ Validación de seguridad obligatoria
      if (mounted) {
        setState(() {
          _nombre =
              nombre; // Asegúrate de que 'nombre' esté definido en este scope
          _cargando = false;
        });
      }
    }
  }
Map<String, dynamic> _calcularNivel(int puntos) {
  const List<int> puntosNivel = [
    0, 1000, 1250, 1500, 1750, 2000,
    2300, 2600, 2900, 3200, 3500,
    3850, 4200, 4550, 4900, 5250,
    5600, 5950, 6300, 6650, 7000,
  ];
  int nivel = 0;
  for (int i = 1; i < puntosNivel.length; i++) {
    if (puntos >= puntosNivel[i]) nivel = i;
    else break;
  }
  int puntosActual = puntosNivel[nivel];
  int puntosNext = nivel < 20 ? puntosNivel[nivel + 1] : 7000;
  double progreso = nivel < 20
      ? (puntos - puntosActual) / (puntosNext - puntosActual)
      : 1.0;
  return {
    'nivel': nivel,
    'progreso': progreso.clamp(0.0, 1.0),
    'puntosNext': puntosNext,
  };
}
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
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.star, color: Colors.orange, size: 35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Hola, $_nombre!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Nivel ${_calcularNivel(_puntos)['nivel']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerOption(
              Icons.emoji_events,
              'Tienda de recompensas',
              Colors.purple,
              () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TiendaRecompensasHijoScreen(),
                  ),
                );
              },
            ),
            _buildDrawerOption(
              Icons.rocket_launch,
              'Mis desafíos',
              Colors.orange,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisDesafiosScreen(),
                  ),
                );
              },
            ),
            _buildDrawerOption(Icons.history, 'Mi Actividad', Colors.white, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MiActividadScreen(),
                ),
              );
            }),
            _buildDrawerOption(
              Icons.help_outline,
              'Guía de la app',
              Colors.purple,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuiaHijoScreen()),
                );
              },
            ),
            const Divider(),
            _buildDrawerOption(
              Icons.exit_to_app,
              'Cerrar Sesión',
              Colors.red,
              () async {
                final auth = AuthService();
                await auth.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh:
                    _cargarDatos, // Implementa refresco manual como en el Padre[cite: 1]
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Hola, $_nombre!',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Nivel ${_calcularNivel(_puntos)['nivel']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.greenAccent,
                              child: Icon(
                                Icons.face,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildMascotaCard(),
                        const SizedBox(height: 20),
                        const Text(
                          'Desafíos disponibles:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Generación dinámica de desafíos desde el Backend
                        _desafios.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No hay desafíos disponibles",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            : Column(
                                children: _desafios.map((desafio) {
                                  return _buildChallengeCard(
                                    context, // Agregamos el context para navegar
                                    desafio, // Pasamos el mapa completo
                                    _pendientes.contains(desafio['id'].toString()),
                                  );
                                }).toList(),
                              ),

                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TiendaRecompensasHijoScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Recompensas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawerOption(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMascotaCard() {
    final nivelInfo = _calcularNivel(_puntos);
    final int nivel = nivelInfo['nivel'];
    final double progreso = nivelInfo['progreso'];
    final int puntosNext = nivelInfo['puntosNext'];
    final pet = PetModel(puntos: _puntos);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Image.asset(
                pet.imagePath,
                key: ValueKey(pet.imagePath),
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RaccuPoints',
            style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '$_puntos pts',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.greenAccent),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nivel $nivel — faltan ${puntosNext - _puntos} pts para el siguiente',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 15,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progreso * 100).toInt()}%',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Map<String, dynamic> desafio,
    bool esPendiente,
  ) {
    final String titulo = desafio['titulo'] ?? 'Desafío';
    final String descripcion = desafio['descripcion'] ?? 'Sin descripción';
    final String puntos = '+${desafio['puntos']} pts';
    final String dificultad =
        desafio['dificultad'] ?? 'fácil'; // Valor por defecto

    // Normalizamos el tipo
    String tipoRaw = (desafio['tipo'] ?? 'general').toString().toLowerCase();
    if (tipoRaw == 'cognitivo') tipoRaw = 'cognitiva';
    if (tipoRaw == 'fisico') tipoRaw = 'fisica';

    final IconData icono = _getIcono(tipoRaw);
    final Color color = _getColor(tipoRaw);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior:
          Clip.antiAlias, // Mantiene el badge dentro del radio del Card
      child: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icono, color: color),
              ),
              title: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                ), // Bajamos un poco el título por el badge
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              subtitle: Text(
                tipoRaw.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  puntos,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              descripcion,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.indigo,
                            ),
                            onPressed: () => _tts.speak(descripcion),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: esPendiente
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_top),
                                label: const Text('Pendiente de revisión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade200,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleDesafioScreen(desafio: desafio),
                                    ),
                                  );
                                  if (resultado == true) _cargarDatos();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  '¡Ir a realizar el desafío!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ETIQUETA DE DIFICULTAD (BADGE)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getDificultadColor(dificultad),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                dificultad.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
