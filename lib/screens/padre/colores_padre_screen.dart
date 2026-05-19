// lib/screens/padre/colores_padre_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart'; // <-- Tu nuevo archivo

class ColoresPadreScreen extends StatefulWidget {
  const ColoresPadreScreen({super.key});

  @override
  State<ColoresPadreScreen> createState() => _ColoresPadreScreenState();
}

class _ColoresPadreScreenState extends State<ColoresPadreScreen> {
  String _seleccionada = 'Celeste Neutro';

  @override
  void initState() {
    super.initState();
    _seleccionada = context.read<TemaPadreProvider>().paletaPadre;
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Colores del Panel',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: temaPadre.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración Visual (Padre)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige una combinación de colores neutros para la gestión de la aplicación.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            // Muestra solo tus paletas independientes del padre
            ...AppPaletasPadre.paletas.entries.map((entry) {
              final nombre = entry.key;
              final paleta = entry.value;
              final esSeleccionada = _seleccionada == nombre;

              return GestureDetector(
                onTap: () => setState(() => _seleccionada = nombre),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: esSeleccionada ? paleta.background : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: esSeleccionada
                          ? paleta.primary
                          : Colors.grey.shade300,
                      width: esSeleccionada ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCirculo(paleta.primary),
                      const SizedBox(width: 8),
                      _buildCirculo(paleta.accent),
                      const SizedBox(width: 8),
                      _buildCirculo(paleta.background, tieneBorde: true),
                      const SizedBox(width: 16),
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: esSeleccionada
                              ? paleta.primary
                              : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (esSeleccionada)
                        Icon(
                          Icons.check_circle,
                          color: paleta.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.read<TemaPadreProvider>().cambiarTemaPadre(
                  _seleccionada,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppPaletasPadre.paletas[_seleccionada]!.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Aplicar colores de Padre',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCirculo(Color color, {bool tieneBorde = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: tieneBorde ? Border.all(color: Colors.grey.shade300) : null,
      ),
    );
  }
}
