import 'package:flutter/material.dart';

class MisDesafiosScreen extends StatelessWidget {
  const MisDesafiosScreen({super.key});

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

      body: Column(
        children: [
          // progreso
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatWidget(
                  label: 'Completados',
                  value: '12',
                  color: Colors.green,
                ),
                _StatWidget(
                  label: 'Pendientes',
                  value: '3',
                  color: Colors.orange,
                ),
                _StatWidget(
                  label: 'Puntos hoy',
                  value: '+150',
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

          // desafios
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDesafioCard(
                  context,
                  'Suma Rápida',
                  'Resuelve 10 ejercicios de matemáticas.',
                  '25 pts',
                  Icons.calculate,
                  Colors.blue,
                ),
                _buildDesafioCard(
                  context,
                  'Ordenando mi cuarto',
                  'Toma una foto de tu cama estirada.',
                  '50 pts',
                  Icons.bed,
                  Colors.orange,
                ),
                _buildDesafioCard(
                  context,
                  'Lectura Diaria',
                  'Lee 10 páginas de tu libro favorito.',
                  '30 pts',
                  Icons.menu_book,
                  Colors.purple,
                ),
                _buildDesafioCard(
                  context,
                  'Haz ejercicio',
                  'Realiza 10 sentadillas.',
                  '30 pts',
                  Icons.fitness_center,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// tarjetas de desafio
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
        trailing: Column(
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
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
