import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO

const _recompensas = [
  {
    'nombre': 'Elegir la película',
    'icono': Icons.movie,
    'color': Color(0xFFFF9800),
    'puntos': 150,
  },
  {
    'nombre': 'Postre especial',
    'icono': Icons.icecream,
    'color': Color(0xFFE91E63),
    'puntos': 250,
  },
  {
    'nombre': 'Elegir la cena',
    'icono': Icons.restaurant,
    'color': Color(0xFF009688),
    'puntos': 400,
  },
  {
    'nombre': 'Noche de juegos de mesa',
    'icono': Icons.casino,
    'color': Color(0xFF3F51B5),
    'puntos': 550,
  },
  {
    'nombre': 'Noche de pizza',
    'icono': Icons.local_pizza,
    'color': Color(0xFFF44336),
    'puntos': 700,
  },
  {
    'nombre': 'Salida al parque',
    'icono': Icons.park,
    'color': Color(0xFF4CAF50),
    'puntos': 850,
  },
  {
    'nombre': '30 min extra de juegos',
    'icono': Icons.videogame_asset,
    'color': Color(0xFF9C27B0),
    'puntos': 1000,
  },
  {
    'nombre': '30 min menos al desbloqueo',
    'icono': Icons.lock_open,
    'color': Color(0xFF1A237E),
    'puntos': 1200,
  },
];

class RecompensasScreen extends StatefulWidget {
  const RecompensasScreen({super.key});

  @override
  State<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  final List<bool> _activas = List.filled(_recompensas.length, false);

  @override
  Widget build(BuildContext context) {
    // Escucha el tema exclusivo del padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Tienda de Recompensas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary, // <-- APPBAR REACTIVO
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Tu degradado insignia al 0.62 para armonizar la tienda de premios
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _recompensas.length,
          itemBuilder: (context, i) {
            final r = _recompensas[i];
            final color = r['color'] as Color;
            final activa = _activas[i];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: activa
                      ? color.withOpacity(0.15)
                      : Colors.grey.shade100,
                  child: Icon(
                    r['icono'] as IconData,
                    color: activa ? color : Colors.grey,
                  ),
                ),
                title: Text(
                  r['nombre'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${r['puntos']} MapachePoints',
                  style: TextStyle(
                    color: activa ? color : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: activa,
                activeColor: temaPadre
                    .primary, // <-- CAMBIADO EL COLOR DEL INTERRUPTOR ACTIVO AL TUYO
                onChanged: (val) => setState(() => _activas[i] = val),
              ),
            );
          },
        ),
      ),
    );
  }
}
