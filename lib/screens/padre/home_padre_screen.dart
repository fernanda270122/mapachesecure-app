import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';

class HomePadreScreen extends StatefulWidget {
  const HomePadreScreen({super.key});

  @override
  State<HomePadreScreen> createState() => _HomePadreScreenState();
}

class _HomePadreScreenState extends State<HomePadreScreen> {
  String _nombre = '';
  List<dynamic> _hijos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? '';
    final padreId = prefs.getString('user_id') ?? '';

    try {
      final api = ApiService();
      final hijos = await api.get('/usuarios/$padreId/hijos');
      setState(() {
        _nombre = nombre;
        _hijos = hijos is List ? hijos : [];
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
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1A237E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF1A237E),
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
              Icons.insert_chart_outlined,
              'Resumen de la semana',
              () {},
            ),
            _buildDrawerItem(
              context,
              Icons.settings_suggest,
              'Límites y Reglas',
              () {},
            ),
            const Divider(),
            _buildDrawerItem(context, Icons.exit_to_app, 'Cerrar Sesión', () {
              Navigator.pushReplacementNamed(context, '/');
            }),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividad de hoy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildResumenHoy(),
                  const SizedBox(height: 30),
                  const Text(
                    '¿En qué gastaron el tiempo?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildCuadriculaCategorias(),
                  const SizedBox(height: 35),
                  const Text(
                    'Hijos conectados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              .map((hijo) => _buildTarjetaHijo(
                                    hijo['nombre'] ?? 'Sin nombre',
                                    'Smartphone',
                                    Icons.smartphone,
                                    Colors.green,
                                  ))
                              .toList(),
                        ),
                ],
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
          _buildDatoIndividual('Tiempo', '2h 45m', Icons.access_time, Colors.blue),
          _buildDatoIndividual('Desafíos', '3 / 6', Icons.task_alt, Colors.green),
          _buildDatoIndividual('Puntos', '75', Icons.stars, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCuadriculaCategorias() {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildChipCategoria('Juegos', Icons.videogame_asset, Colors.orange, '45m'),
          _buildChipCategoria('Social', Icons.groups, Colors.purple, '30m'),
          _buildChipCategoria('Estudio', Icons.menu_book, Colors.green, '1h 10m'),
          _buildChipCategoria('Videos', Icons.play_circle_filled, Colors.red, '20m'),
        ],
      ),
    );
  }

  Widget _buildDatoIndividual(String titulo, String valor, IconData icono, Color color) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 5),
        Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildChipCategoria(String nombre, IconData icono, Color color, String duracion) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 5),
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(duracion, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTarjetaHijo(String nombre, String detalle, IconData icono, Color colorEstado) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icono, color: const Color(0xFF1A237E)),
        ),
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(detalle),
        trailing: Icon(Icons.circle, color: colorEstado, size: 12),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A237E)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
