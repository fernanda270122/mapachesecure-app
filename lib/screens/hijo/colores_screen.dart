import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/theme/app_paletas.dart';

class ColoresScreen extends StatefulWidget {
  const ColoresScreen({super.key});

  @override
  State<ColoresScreen> createState() => _ColoresScreenState();
}

class _ColoresScreenState extends State<ColoresScreen> {
  String _seleccionada = 'Lavanda';

  @override
  void initState() {
    super.initState();
    _seleccionada = context.read<TemaProvider>().paleta;
  }

  @override
  Widget build(BuildContext context) {
    final temaActual = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: temaActual.background,
      appBar: AppBar(
        title: const Text('Colores', style: TextStyle(color: Colors.white)),
        backgroundColor: temaActual.primary,
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
              'Elige un tema de colores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El color cambia el fondo, la barra y los botones de la app.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ...AppPaletas.paletas.entries.map((entry) {
              final nombre = entry.key;
              final paleta = entry.value;
              final seleccionada = _seleccionada == nombre;
              return GestureDetector(
                onTap: () => setState(() => _seleccionada = nombre),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: seleccionada ? paleta.background : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: seleccionada ? paleta.primary : Colors.grey.shade300,
                      width: seleccionada ? 2.5 : 1,
                    ),
                    boxShadow: seleccionada
                        ? [BoxShadow(color: paleta.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      _circulo(paleta.primary),
                      const SizedBox(width: 8),
                      _circulo(paleta.accent),
                      const SizedBox(width: 8),
                      _circulo(paleta.background, borde: true),
                      const SizedBox(width: 16),
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: seleccionada ? paleta.primary : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (seleccionada)
                        Icon(Icons.check_circle, color: paleta.primary, size: 24),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.read<TemaProvider>().cambiar(_seleccionada);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPaletas.paletas[_seleccionada]!.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Aplicar tema', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circulo(Color color, {bool borde = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borde ? Border.all(color: Colors.grey.shade300) : null,
      ),
    );
  }
}
