import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';

class HomeHijoScreen extends StatelessWidget {
  const HomeHijoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // menu hamburguesa
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlue, Colors.blueAccent],
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
                  const Text(
                    '¡Hola, Mimi!',
                    style: TextStyle(
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
              'Mis Premios',
              Colors.purple,
              () {},
            ),
            _buildDrawerOption(
              Icons.rocket_launch,
              'Mis desafíos',
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisDesafiosScreen(),
                  ),
                );
              },
            ),
            _buildDrawerOption(Icons.history, 'Mi Actividad', Colors.blue, () {
              Navigator.pop(context); // Cierra el menú
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
              () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),

      // boton del menu
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 2, 148, 216),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // saludo que aparece debajo del appbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Hola, Mimi!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
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
                    child: Icon(Icons.face, size: 40, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // mapachepoints
              _buildPointsCard(),
              const SizedBox(height: 30),

              // desafios
              const Text(
                'Desafíos disponibles:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              _buildChallengeCard(
                '[Cognitivo] Suma rápida',
                '+25 pts | 5 min',
                Icons.calculate,
                Colors.blue,
              ),
              _buildChallengeCard(
                '[Físico] 10 sentadillas',
                '+30 pts | 10 min',
                Icons.fitness_center,
                Colors.green,
              ),
              _buildChallengeCard(
                '[Hogar] Tender cama',
                '+20 pts | Sin límite',
                Icons.bed,
                Colors.orange,
              ),

              const SizedBox(height: 30),

              // premios
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.emoji_events, color: Colors.white),
                  label: const Text(
                    'VER MIS PREMIOS',
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
    );
  }

  // tarjeta para lo que esta dentro del menu de hamburguesa
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

  // tarjeta de los mapachepoints
  Widget _buildPointsCard() {
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
          const Text(
            '1.250 pts',
            style: TextStyle(
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
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 15,
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 5),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '60%',
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // tarjeta de desafio
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
