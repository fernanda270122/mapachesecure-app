import 'package:flutter/material.dart';                                                                                                                                                       
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

class GuiaHijoScreen extends StatelessWidget {
  const GuiaHijoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text('Guía de la app',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _seccion(context,
            icono: Icons.waving_hand,
            titulo: '¡Bienvenido a Raccu!',
            pasos: [
              'Esta app te ayuda a organizar tu tiempo con el celular.',
              'Completa desafíos, gana puntos y haz crecer a tu mapache Raccu.',
            ],
          ),
          _seccion(context,
            icono: Icons.task_alt,
            titulo: '¿Cómo funcionan los desafíos?',
            pasos: [
              'En "Mis desafíos" verás las tareas que te asignó tu papá o mamá.',
              'Pueden ser ejercicios, tareas del hogar o actividades mentales.',
              'Completa el desafío y sube una foto como evidencia.',
              'Cuando tu papá o mamá apruebe la foto, ¡ganas puntos!',
            ],
          ),
          _seccion(context,
            icono: Icons.star,
            titulo: '¿Para qué sirven los puntos?',
            pasos: [
              'Cada desafío completado te da puntos.',
              'Con tus puntos puedes canjear recompensas en la tienda.',
              'Las recompensas las elige tu papá o mamá especialmente para ti.',
            ],
          ),
          _seccion(context,
            icono: Icons.pets,
            titulo: 'Tu mascota Raccu',
            pasos: [
              'Raccu es tu mapache personal.',
              'Gana más puntos para que Raccu crezca.',
              'Con 0-199 puntos es bebé, con 200-499 es mediano y con 500+ es grande.',
              '¡Cuídalo completando tus desafíos!',
            ],
          ),
          _seccion(context,
            icono: Icons.block,
            titulo: '¿Por qué están bloqueadas mis apps?',
            pasos: [
              'Tu papá o mamá puede bloquear algunas apps por un tiempo.',
              'Completa tus desafíos para poder usarlas de nuevo.',
              'El bloqueo es para ayudarte a organizar mejor tu tiempo.',
            ],
          ),
          _seccion(context,
            icono: Icons.lightbulb_outline,
            titulo: 'Consejos',
            pasos: [
              'Completa tus desafíos todos los días para acumular más puntos.',
              'Habla con tus papás si crees que algún límite es muy estricto.',
              'Recuerda que Raccu crece contigo. ¡Sé constante!',
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccion(BuildContext context, {
    required IconData icono,
    required String titulo,
    required List<String> pasos,
  }) {
    final primary = context.watch<TemaProvider>().colores.primary;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.1),
                  child: Icon(icono, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pasos.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}. ',
                          style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(e.value,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}