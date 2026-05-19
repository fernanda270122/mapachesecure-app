// lib/screens/padre/colores_padre_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart';

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

    // CONTROL DE CHOQUES GLOBALES DE LA PANTALLA
    final esFondoOscuroGlobal = temaPadre.background == const Color(0xFF121212);
    final esFondoBlancoGlobal = temaPadre.background == const Color(0xFFFFFFFF);

    // Determinamos el color base de los textos fijos según el fondo de la pantalla
    Color colorTextoFijoPrincipal = Colors.black87;
    Color colorTextoFijoSecundario = Colors.black54;

    if (esFondoOscuroGlobal) {
      colorTextoFijoPrincipal = Colors.white;
      colorTextoFijoSecundario = Colors.white60;
    } else if (esFondoBlancoGlobal) {
      colorTextoFijoPrincipal =
          Colors.black; // Negro absoluto para máxima legibilidad sobre blanco
      colorTextoFijoSecundario = Colors.black54;
    }

    // Rescatamos la paleta seleccionada de forma segura para usarla en el ElevatedButton
    final paletaActualElegida =
        AppPaletasPadre.paletas[_seleccionada] ??
        AppPaletasPadre.paletas['Celeste Neutro']!;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Colores del Panel',
          style: TextStyle(
            color: temaPadre.primary == const Color(0xFFE2E8F0)
                ? Colors.black87
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: temaPadre.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: temaPadre.primary == const Color(0xFFE2E8F0)
                ? Colors.black87
                : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración Visual (Padre)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorTextoFijoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elige una combinación de colores neutros para la gestión de la aplicación.',
                style: TextStyle(color: colorTextoFijoSecundario),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: AppPaletasPadre.paletas.entries.map((entry) {
                      final nombre = entry.key;
                      final paleta = entry.value;
                      final esSeleccionada = _seleccionada == nombre;

                      // --- CONTROL DE CHOQUE DENTRO DE CADA TARJETA ---
                      final esTarjetaNegra =
                          paleta.background == const Color(0xFF121212);
                      final esTarjetaBlanca =
                          paleta.background == const Color(0xFFFFFFFF);

                      // Definir fondo base de las tarjetas inactivas
                      Color fondoTarjetaNormal = Colors.white;
                      if (esFondoOscuroGlobal) {
                        fondoTarjetaNormal = const Color(0xFF1E1E1E);
                      } else if (esFondoBlancoGlobal) {
                        fondoTarjetaNormal = const Color(0xFFF8FAFC);
                      }

                      // Calcular color del texto de la etiqueta de la paleta
                      Color colorTextoTarjeta;
                      if (esSeleccionada) {
                        colorTextoTarjeta = esTarjetaNegra
                            ? Colors.white
                            : Colors.black87;
                      } else {
                        colorTextoTarjeta = esFondoOscuroGlobal
                            ? Colors.white
                            : Colors.black87;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _seleccionada = nombre),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: esSeleccionada
                                ? paleta.background
                                : fondoTarjetaNormal,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: esSeleccionada
                                  ? paleta.primary
                                  : (esFondoOscuroGlobal
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300),
                              width: esSeleccionada ? 2.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildCirculo(paleta.primary),
                              const SizedBox(width: 8),
                              _buildCirculo(paleta.accent),
                              const SizedBox(width: 8),
                              _buildCirculo(
                                paleta.background,
                                tieneBorde: true,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorTextoTarjeta,
                                ),
                              ),
                              const Spacer(),
                              if (esSeleccionada)
                                Icon(
                                  Icons.check_circle,
                                  color: esTarjetaBlanca && esSeleccionada
                                      ? Colors.blueGrey
                                      : paleta.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<TemaPadreProvider>().cambiarTemaPadre(
                    _seleccionada,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: paletaActualElegida
                      .primary, // <-- BLINDADO: Usa la paleta segura rescatada arriba
                  foregroundColor:
                      paletaActualElegida.primary == const Color(0xFFE2E8F0)
                      ? Colors.black87
                      : Colors.white, // <-- BLINDADO
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  side:
                      _seleccionada ==
                          'Blanco grisáceo' // <-- CORREGIDO: "c" y tilde exacta
                      ? BorderSide(color: Colors.grey.shade300, width: 1)
                      : null,
                ),
                child: Text(
                  'Aplicar colores de Padre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        _seleccionada ==
                            'Blanco grisáceo' // <-- CORREGIDO: "c" y tilde exacta
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
        border: tieneBorde
            ? Border.all(color: Colors.grey.shade400, width: 0.8)
            : null,
      ),
    );
  }
}
