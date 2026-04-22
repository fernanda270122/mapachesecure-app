import 'package:flutter/material.dart';

class HomePadreScreen extends StatelessWidget {
  const HomePadreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Fondo gris muy claro para que resalten las tarjetas
      // 1. MENÚ LATERAL (Navegación sencilla)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1A237E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF1A237E),
                      size: 35,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Juanito alcachofa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN: RESUMEN GENERAL
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

            // SECCIÓN: DESGLOSE POR ACTIVIDAD
            const Text(
              '¿En qué gastaron el tiempo?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildCuadriculaCategorias(),

            const SizedBox(height: 35),

            // SECCIÓN: ESTADO DE DISPOSITIVOS
            const Text(
              'Hijos conectados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildTarjetaHijo(
              'Mimi',
              'Smartphone - En línea',
              Icons.smartphone,
              Colors.green,
            ),
            _buildTarjetaHijo(
              'Noche',
              'Tablet - Tiempo Agotado',
              Icons.tablet_android,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUES DE CONSTRUCCIÓN (Para mantener el código ordenado) ---

  // Tarjeta blanca con las 3 estadísticas principales
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
            '2h 45m',
            Icons.access_time,
            Colors.blue,
          ),
          _buildDatoIndividual(
            'Desafíos',
            '3 / 6',
            Icons.task_alt,
            Colors.green,
          ),
          _buildDatoIndividual('Puntos', '75', Icons.stars, Colors.orange),
        ],
      ),
    );
  }

  // Cuadricula de categorías corregida (Suman 2h 45m)
  Widget _buildCuadriculaCategorias() {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildChipCategoria(
            'Juegos',
            Icons.videogame_asset,
            Colors.orange,
            '45m',
          ),
          _buildChipCategoria('Social', Icons.groups, Colors.purple, '30m'),
          _buildChipCategoria(
            'Estudio',
            Icons.menu_book,
            Colors.green,
            '1h 10m',
          ),
          _buildChipCategoria(
            'Videos',
            Icons.play_circle_filled,
            Colors.red,
            '20m',
          ),
        ],
      ),
    );
  }

  // Widget para cada dato del resumen (Tiempo, Desafíos, etc.)
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

  // Widget para los botones de categorías
  Widget _buildChipCategoria(
    String nombre,
    IconData icono,
    Color color,
    String duracion,
  ) {
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
          Text(
            nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            duracion,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para la lista de hijos
  Widget _buildTarjetaHijo(
    String nombre,
    String detalle,
    IconData icono,
    Color colorEstado,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icono, color: const Color(0xFF1A237E)),
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

  // Item del menú lateral
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A237E)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
