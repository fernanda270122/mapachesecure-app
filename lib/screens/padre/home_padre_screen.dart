import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/padre/revisar_evidencias_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/screens/padre/desafios_screen.dart';
import 'package:mapachesecure_app/screens/padre/agregar_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/configurar_hijo.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/padre/tienda_recompensas_screen.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/screens/padre/consejos_padres_screen.dart';
import 'package:mapachesecure_app/screens/padre/canjes_pendientes_screen.dart';

class HomePadreScreen extends StatefulWidget {
  const HomePadreScreen({super.key});

  @override
  State<HomePadreScreen> createState() => _HomePadreScreenState();
}

class _HomePadreScreenState extends State<HomePadreScreen> {
  String _nombre = '';
  List<dynamic> _hijos = [];
  bool _cargando = true;
  int _totalDesafios = 0;
  int _totalPuntos = 0;
  int _totalMinutos = 0;

  final PageController _carruselController = PageController();
  int _carruselPagina = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _carruselController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? '';
    final padreId = prefs.getString('user_id') ?? '';

    try {
      final api = ApiService();
      final hijos = await api.get('/usuarios/$padreId/hijos');
      final listaHijos = hijos is List ? hijos : [];

      int totalDesafios = 0;
      int totalPuntos = 0;
      int totalMinutos = 0;

      for (final hijo in listaHijos) {
        final hijoId = hijo['id'];

        final completados = await api.get('/desafios/completados/$hijoId');
        final numDesafios = completados is List ? completados.length : 0;
        totalDesafios += numDesafios;

        final puntos = await api.get('/desafios/puntos/$hijoId');
        final numPuntos = puntos is Map ? ((puntos['total_puntos'] as num?)?.toInt() ?? 0) : 0;
        totalPuntos += numPuntos;

        final estado = await api.get('/apps/estado/$hijoId');
        final numMinutos = estado is Map ? ((estado['minutos_usados'] as num?)?.toInt() ?? 0) : 0;
        totalMinutos += numMinutos;

        hijo['stat_desafios'] = numDesafios;
        hijo['stat_puntos'] = numPuntos;
        hijo['stat_minutos'] = numMinutos;
      }

      setState(() {
        _nombre = nombre;
        _hijos = listaHijos;
        _totalDesafios = totalDesafios;
        _totalPuntos = totalPuntos;
        _totalMinutos = totalMinutos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _nombre = nombre;
        _hijos = [];
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nombre.isNotEmpty ? _nombre : 'Cargando...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Administrador de Familia',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.home,
              'Inicio / Panel de control',
              () => Navigator.pop(context),
            ),

            _buildDrawerItem(
              context,
              Icons.person_add,
              'Agregar Hijo',
              () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgregarHijoScreen(),
                  ),
                );
                if (mounted) _cargarDatos();
              },
            ),

            _buildDrawerItem(
              context,
              Icons.assignment_turned_in,
              'Gestionar Desafíos',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DesafiosScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              context,
              Icons.fact_check_outlined, 
              'Revisar Evidencias',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RevisarEvidenciasScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(context, Icons.stars, 'Tienda de Recompensas', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TiendaRecompensasScreen(),
                ),
              );
            }),

            _buildDrawerItem(
              context,
              Icons.card_giftcard,
              'Canjes Pendientes',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CanjesPendientesScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              context,
              Icons.lightbulb_outline,
              'Consejos para Padres',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConsejosPadresScreen()),
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(context, Icons.exit_to_app, 'Cerrar Sesión', () async {
              final auth = AuthService();
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppBackground(child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCarrusel(),
                      const SizedBox(height: 30),
                    const Text(
                      'Hijos conectados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _hijos.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No tienes hijos registrados aún',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Column(
                            children: _hijos
                                .map(
                                  (hijo) => GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfigurarHijoScreen(hijo: hijo),
                                      ),
                                    ),
                                    child: _buildTarjetaHijo(hijo),
                                  ),
                                )
                                .toList(),
                          ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildResumenHoy() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          _buildDatoIndividual(
            'Tiempo',
            _totalMinutos < 60
                ? '${_totalMinutos}m'
                : '${_totalMinutos ~/ 60}h ${_totalMinutos % 60}m',
            Icons.access_time,
            Colors.blue,
          ),
          _buildDatoIndividual(
            'Desafíos',
            '$_totalDesafios',
            Icons.task_alt,
            Colors.green,
          ),
          _buildDatoIndividual(
            'Puntos',
            '$_totalPuntos',
            Icons.stars,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDatoIndividual(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTarjetaHijo(Map<dynamic, dynamic> hijo) {
    final minutos = hijo['stat_minutos'] ?? 0;
    final desafios = hijo['stat_desafios'] ?? 0;
    final puntos = hijo['stat_puntos'] ?? 0;
    final tiempoStr = minutos < 60
        ? '${minutos}m'
        : '${minutos ~/ 60}h ${minutos % 60}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: const Icon(Icons.child_care, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hijo['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatChip(Icons.access_time, tiempoStr, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.task_alt, '$desafios', Colors.green),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.stars, '$puntos pts', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icono, String valor, Color color) {
    return Row(
      children: [
        Icon(icono, size: 13, color: color),
        const SizedBox(width: 3),
        Text(valor, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
  Widget _buildCarrusel() {
    final slides = [
      {'color': const Color(0xFF7C4DFF), 'icono': Icons.shield},
      {'color': const Color(0xFF00897B), 'icono': Icons.child_care},
      {'color': const Color(0xFF1565C0), 'icono': Icons.stars},
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _carruselController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _carruselPagina = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: slide['color'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(slide['icono'] as IconData, color: Colors.white, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'RaccuApp',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'by CAVY',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _carruselPagina == i ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _carruselPagina == i ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
