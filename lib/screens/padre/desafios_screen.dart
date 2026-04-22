import 'package:flutter/material.dart';

class DesafiosScreen extends StatelessWidget {
  const DesafiosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionar Desafíos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAdminChallengeCard(
            'Tarea: Matemáticas',
            'Pendiente de revisión',
            Colors.orange,
            Icons.calculate,
          ),
          _buildAdminChallengeCard(
            'Hogar: Limpiar cuarto',
            'Completado',
            Colors.green,
            Icons.bed,
          ),
          _buildAdminChallengeCard(
            'Hábito: Leer 15 min',
            'Activo',
            Colors.blue,
            Icons.menu_book,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        backgroundColor: const Color(0xFF2ECC71),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAdminChallengeCard(
    String titulo,
    String estado,
    Color color,
    IconData icono,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Estado: $estado'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          onPressed: () {},
        ),
      ),
    );
  }
}
