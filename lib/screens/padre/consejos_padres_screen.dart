import 'package:flutter/material.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';                                                                                                                                   

class ConsejosPadresScreen extends StatelessWidget {                                                                                                                                            
const ConsejosPadresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consejos para Padres',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
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
          ),
          _seccion(
            icono: Icons.child_care,
            titulo: '¿Cómo agregar a tu hijo?',
            pasos: [
              'En la pantalla principal toca el botón "Agregar hijo".',
              'Ingresa su nombre, edad y una contraseña para que él pueda iniciar sesión.',
              'Una vez creado, aparecerá en tu lista de hijos.',
            ],
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
          ),
          _seccion(
            icono: Icons.star,
            titulo: '¿Cómo funcionan las recompensas?',
            pasos: [
              'El padre puede activar hasta 3 recompensas a la vez.',
              'El hijo canjea sus puntos por las recompensas disponibles.',
              'Puedes elegir recompensas del catálogo o crear las tuyas.',
            ],
          ),
          _seccion(
            icono: Icons.pets,
            titulo: 'La mascota Raccu',
            pasos: [
              'Raccu es la mascota mapache de tu hijo.',
              'Crece según los puntos acumulados: bebé (0-199), mediano (200-499) y grande (500+).',
              'Motiva a tu hijo a completar desafíos para que Raccu crezca.',
            ],
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
          ),
        ],
      ),
    );
  }

  Widget _seccion({
    required IconData icono,
    required String titulo,
    required List<String> pasos,
  }) {
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
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(icono, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
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
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 13, color: Colors.black87))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}