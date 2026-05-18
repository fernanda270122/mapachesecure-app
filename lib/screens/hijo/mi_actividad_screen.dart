import 'package:flutter/material.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

class MiActividadScreen extends StatelessWidget {
  const MiActividadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text('Mi Actividad'),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo vas hoy?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tema.onBackground,
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Tiempo Total
            _buildTotalTimeCard(tema.accent),

            const SizedBox(height: 30),

            Text(
              'Tiempo por Aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tema.onBackground),
            ),
            const SizedBox(height: 15),

            // Lista de Apps (Simulado, luego lo conectas a Supabase)
            _buildAppUsageTile(
              'YouTube Kids',
              '45 min',
              Icons.play_arrow,
              Colors.red,
              0.7,
            ),
            _buildAppUsageTile(
              'Roblox',
              '1h 10 min',
              Icons.videogame_asset,
              Colors.green,
              0.9,
            ),
            _buildAppUsageTile(
              'TikTok',
              '15 min',
              Icons.music_note,
              Colors.black,
              0.2,
            ),

            const SizedBox(height: 30),

            // Mensaje motivador
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Vas muy bien! Recuerda descansar la vista cada 20 minutos.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalTimeCard(Color accentColor) {
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
            'Tiempo Total de Pantalla',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '2h 10m',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const Text('de 3h permitidas', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 12,
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageTile(
    String app,
    String time,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(app, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
