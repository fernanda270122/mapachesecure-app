import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO

class ConsejosPadresScreen extends StatelessWidget {
  const ConsejosPadresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el tema del padre seleccionado dinámicamente
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Consejos para Padres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary, // <-- APPBAR REACTIVO
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Tu degradado insignia al 0.62 para armonizar el fondo de consejos
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _seccion(
              icono: Icons.install_mobile,
              titulo: '¿Cómo instalar la app en el celular de tu hijo?',
              pasos: [
                'Registra a tu hijo desde el botón "Agregar hijo" en la pantalla principal.',
                'Al completar el registro aparecerá un código QR en pantalla.',
                'Dale el celular a tu hijo y pídele que abra la cámara y apunte al QR.',
                'Se abrirá el link de descarga — toca "Descargar".',
                'Una vez descargado, abre el archivo desde las notificaciones o la carpeta Descargas.',
                'Si Android pide permiso, ve a Ajustes → Aplicaciones → Instalar apps de fuentes desconocidas y actívalo.',
                'Instala la app, ingresa con el correo y contraseña que creaste para tu hijo.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.child_care,
              titulo: '¿Cómo agregar a tu hijo?',
              pasos: [
                'En la pantalla principal toca el botón "Agregar hijo".',
                'Ingresa su nombre, edad y una contraseña para que él pueda iniciar sesión.',
                'Una vez creado, aparecerá en tu lista de hijos.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.block,
              titulo: '¿Cómo configurar bloqueos?',
              pasos: [
                'Toca el nombre de tu hijo en la pantalla principal.',
                'Selecciona el modo de bloqueo: Inmediato, Horario o Calendario.',
                'El bloqueo inmediato activa la restricción al instante.',
                'El horario permite definir un rango de horas y los días que se repite.',
                'El calendario permite elegir fechas específicas con un horario.',
                'El mínimo de bloqueo por horario es de 2 horas.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.emoji_events,
              titulo: '¿Cómo funcionan los desafíos?',
              pasos: [
                'Los desafíos son tareas que el hijo debe completar para desbloquear apps.',
                'Pueden ser cognitivos, físicos o del hogar.',
                'El hijo sube una foto como evidencia y el padre la aprueba.',
                'Al completar un desafío, el hijo gana puntos.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.star,
              titulo: '¿Cómo funcionan las recompensas?',
              pasos: [
                'El padre puede activar hasta 3 recompensas a la vez.',
                'El hijo canjea sus puntos por las recompensas disponibles.',
                'Puedes elegir recompensas del catálogo o crear las tuyas.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.pets,
              titulo: 'La mascota Raccu',
              pasos: [
                'Raccu es la mascota mapache de tu hijo.',
                'Crece según los puntos acumulados: bebé (0-199), mediano (200-499) y grande (500+).',
                'Motiva a tu hijo a completar desafíos para que Raccu crezca.',
              ],
              colorPrimario: temaPadre.primary,
            ),
            _seccion(
              icono: Icons.lightbulb_outline,
              titulo: 'Consejos generales',
              pasos: [
                'Habla con tu hijo sobre el motivo de los bloqueos, no solo los impongas.',
                'Usa los desafíos como una herramienta positiva, no como castigo.',
                'Revisa el resumen semanal para ver el progreso de tu hijo.',
                'Ajusta los límites según la edad y necesidades de cada hijo.',
              ],
              colorPrimario: temaPadre.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccion({
    required IconData icono,
    required String titulo,
    required List<String> pasos,
    required Color colorPrimario, // <-- PASADO DINÁMICAMENTE
  }) {
    return Card(
      elevation: 1,
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
                  backgroundColor: colorPrimario.withOpacity(
                    0.1,
                  ), // <-- FONDO DEL ÍCONO DINÁMICO
                  child: Icon(icono, color: colorPrimario),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .black87, // <-- ADAPTADO PARA MANTENER LA NEUTRALIDAD
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pasos.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: TextStyle(
                        color:
                            colorPrimario, // <-- NÚMEROS ADAPTADOS A LA PALETA
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
