import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/colores_padre_screen.dart';
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
import 'package:mapachesecure_app/theme/app_paletas_padre.dart';

class HomePadreScreen extends StatefulWidget {
  const HomePadreScreen({super.key});

  @override
  State<HomePadreScreen> createState() => _HomePadreScreenState();
}

class _HomePadreScreenState extends State<HomePadreScreen> {
  String _nombre = '';
  List<dynamic> _hijos = [];
  bool _cargando = true;
  bool _refreshando = false;
  int _totalDesafios = 0;
  int _totalPuntos = 0;
  int _totalMinutos = 0;
  Map<String, Map<String, int>> _statsPorHijo = {};
  Timer? _carruselTimer;

  final PageController _carruselController = PageController();
  int _carruselPagina = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _carruselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_carruselController.hasClients) return;
      final siguiente = (_carruselPagina + 1) % 3;
      _carruselController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carruselController.dispose();
    _carruselTimer?.cancel();
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
      final Map<String, Map<String, int>> statsPorHijo = {};

      for (final hijo in listaHijos) {
        final hijoId = hijo['id'].toString();
        int desafiosHijo = 0;
        int puntosHijo = 0;
        int minutosHijo = 0;

        final completados = await api.get('/desafios/completados/$hijoId');
        if (completados is List) desafiosHijo = completados.length;

        final puntos = await api.get('/desafios/puntos/$hijoId');
        if (puntos is Map && puntos['total_puntos'] != null) {
          puntosHijo = (puntos['total_puntos'] as num).toInt();
        }

        final estado = await api.get('/apps/estado/$hijoId');
        if (estado is Map && estado['minutos_usados'] != null) {
          minutosHijo = (estado['minutos_usados'] as num).toInt();
        }

        statsPorHijo[hijoId] = {
          'desafios': desafiosHijo,
          'puntos': puntosHijo,
          'minutos': minutosHijo,
        };

        totalDesafios += desafiosHijo;
        totalPuntos += puntosHijo;
        totalMinutos += minutosHijo;
      }

      setState(() {
        _nombre = nombre;
        _hijos = listaHijos;
        _totalDesafios = totalDesafios;
        _totalPuntos = totalPuntos;
        _totalMinutos = totalMinutos;
        _statsPorHijo = statsPorHijo;
        _cargando = false;
      });
    } on ApiUnauthorizedException {
      if (_refreshando) {
        await _cerrarSesionPorExpiracion();
        return;
      }
      _refreshando = true;
      final auth = AuthService();
      final renovado = await auth.refreshToken();
      _refreshando = false;
      if (renovado) {
        _cargarDatos();
      } else {
        await _cerrarSesionPorExpiracion();
      }
    } catch (e) {
      setState(() {
        _nombre = nombre;
        _hijos = [];
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesionPorExpiracion() async {
    final auth = AuthService();
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu sesión expiró. Inicia sesión nuevamente.')),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escucha de forma reactiva tus colores exclusivos de Padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: temaPadre.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: temaPadre.primary,
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
              temaPadre.primary,
              () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              Icons.person_add,
              'Agregar Hijo/a',
              temaPadre.primary,
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
              temaPadre.primary,
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
              temaPadre.primary,
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
            _buildDrawerItem(
              context,
              Icons.stars,
              'Tienda de Recompensas',
              temaPadre.primary,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TiendaRecompensasScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.card_giftcard,
              'Canjes Pendientes',
              temaPadre.primary,
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
              temaPadre.primary,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConsejosPadresScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.palette_outlined,
              'Cambiar Color del Panel',
              temaPadre.primary,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ColoresPadreScreen()),
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              Icons.exit_to_app,
              'Cerrar Sesión',
              temaPadre.primary,
              () async {
                final auth = AuthService();
                await auth.logout();
                if (!context.mounted) return;
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
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ¡AQUÍ ESTÁ EL CAMBIO! Renderizamos el carrusel al inicio del body
                      _buildCarrusel(),
                      const SizedBox(height: 25),

                      if (_hijos.length <= 1) ...[
                        const Text(
                          'Actividad de hoy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildResumenHoy(),
                        const SizedBox(height: 30),
                      ],

                      const Text(
                        'Hijos conectados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                              children: _hijos.map((hijo) {
                                final hijoId = hijo['id'].toString();
                                final stats = _statsPorHijo[hijoId];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ConfigurarHijoScreen(hijo: hijo),
                                    ),
                                  ),
                                  child: _hijos.length == 1
                                      ? _buildTarjetaHijo(
                                          hijo['nombre'] ?? 'Sin nombre',
                                          'Toca para configurar',
                                          Icons.smartphone,
                                          Colors.green,
                                          temaPadre.primary,
                                        )
                                      : _buildTarjetaHijoConStats(
                                          hijo['nombre'] ?? 'Sin nombre',
                                          stats,
                                          temaPadre.primary,
                                        ),
                                );
                              }).toList(),
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

  Widget _buildTarjetaHijo(
    String nombre,
    String detalle,
    IconData icono,
    Color colorEstado,
    Color colorIcono,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorIcono.withOpacity(0.1),
          child: Icon(icono, color: colorIcono),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(detalle),
        trailing: Icon(Icons.circle, color: colorEstado, size: 12),
      ),
    );
  }

  Widget _buildTarjetaHijoConStats(
    String nombre,
    Map<String, int>? stats,
    Color colorIcono,
  ) {
    final minutos = stats?['minutos'] ?? 0;
    final tiempoStr = minutos < 60
        ? '${minutos}m'
        : '${minutos ~/ 60}h ${minutos % 60}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorIcono.withOpacity(0.1),
              child: Icon(Icons.smartphone, color: colorIcono),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(Icons.access_time, tiempoStr, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.task_alt, '${stats?['desafios'] ?? 0}', Colors.green),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.stars, '${stats?['puntos'] ?? 0}', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.circle, color: Colors.green, size: 10),
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
        Text(
          valor,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Color colorIcono,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: colorIcono),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildCarrusel() {
    final slides = [
      {
        'imagen': 'assets/carrucel/carrucel1.jpeg',
        'texto':
            'Controla el tiempo de pantalla de tus hijos y bloquea apps cuando lo necesites',
      },
      {
        'imagen': 'assets/carrucel/carrucel2.jpeg',
        'texto':
            'Asigna desafíos cognitivos, físicos y del hogar para que tus hijos ganen RaccuPoints',
      },
      {
        'imagen': 'assets/carrucel/carrucel3.jpeg',
        'texto':
            'Tus hijos pueden canjear sus puntos por recompensas que tú defines',
      },
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
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(slide['imagen'] as String),
                    fit: BoxFit.cover,
                  ),
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
