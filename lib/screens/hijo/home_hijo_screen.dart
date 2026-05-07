import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/tienda_recompensa_hijo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';

class HomeHijoScreen extends StatefulWidget {
  const HomeHijoScreen({super.key});

  @override
  State<HomeHijoScreen> createState() => _HomeHijoScreenState();
}

class _HomeHijoScreenState extends State<HomeHijoScreen> {
  String _nombre = '';
  int _puntos = 0;
  List<dynamic> _desafios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Explorador';
    final hijoId = prefs.getString('user_id') ?? '';

    try {
      final api = ApiService();
      final puntosData = await api.get('/desafios/puntos/$hijoId');
      final desafiosData = await api.get('/desafios/');

      setState(() {
        _nombre = nombre;
        _puntos = puntosData is Map ? (puntosData['total_puntos'] ?? 0) : 0;

        if (desafiosData is List) {
          // 1. Filtramos para que no existan títulos repetidos
          final nombresVistos = <String>{};
          var listaLimpia = desafiosData
              .where((d) => nombresVistos.add(d['titulo'] ?? ''))
              .toList();

          // 2. Mezclamos la lista limpia de forma aleatoria
          listaLimpia.shuffle();

          // 3. Tomamos solo los primeros 3 para el Home
          _desafios = listaLimpia.take(3).toList();
        } else {
          _desafios = [];
        }
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _nombre = nombre;
        _cargando = false;
      });
    }
  }

  // Asignación de iconos basada en las categorías de ia_service.py[cite: 1]
  IconData _getIcono(String? tipo) {
    switch (tipo) {
      case 'cognitiva':
        return Icons.calculate;
      case 'fisica':
        return Icons.fitness_center;
      case 'hogar':
        return Icons.bed;
      default:
        return Icons.star;
    }
  }

  // Asignación de colores basada en las categorías de ia_service.py[cite: 1]
  Color _getColor(String? tipo) {
    switch (tipo) {
      case 'cognitiva':
        return Colors.blue;
      case 'fisica':
        return Colors.green;
      case 'hogar':
        return Colors.orange;
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
                    'Nivel 5 - Explorador Mapache',
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
            _buildDrawerOption(Icons.settings, 'Ajustes', Colors.grey, () {}),
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
                                  child: const Text(
                                    'Nivel 5 - Explorador Mapache',
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
                        _buildPointsCard(),
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

                        // Generación dinámica de desafíos desde el Backend[cite: 1]
                        _desafios.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text("No hay desafíos disponibles"),
                                ),
                              )
                            : Column(
                                children: _desafios.map((desafio) {
                                  return _buildChallengeCard(
                                    desafio['titulo'] ?? 'Desafío',
                                    '+${desafio['puntos']} pts',
                                    _getIcono(desafio['tipo']),
                                    _getColor(desafio['tipo']),
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

  Widget _buildPointsCard() {
    // Definimos una meta de puntos para el nivel actual (ejemplo: 2000 pts)
    const int metaPuntos = 2000;

    // Calculamos el porcentaje real (valor entre 0.0 y 1.0 para el indicador)
    double porcentajeDinamico = _puntos / metaPuntos;
    if (porcentajeDinamico > 1.0)
      porcentajeDinamico = 1.0; // Evita que se pase del 100%

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
          const Text(
            'MapachePoints',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_puntos pts', // Muestra los puntos reales del back
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Progreso nivel:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentajeDinamico, // AHORA ES DINÁMICO
              minHeight: 15,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(porcentajeDinamico * 100).toInt()}%', // Muestra el % real
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    String titulo,
    String desc,
    IconData icono,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 30),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(desc),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Hacer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
