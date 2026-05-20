import 'package:flutter/material.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

class PantallaBloqueoScreen extends StatelessWidget {
  final String horaInicio;
  final String horaFin;

  const PantallaBloqueoScreen({
    super.key,
    required this.horaInicio,
    required this.horaFin,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'App bloqueada',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Horario de bloqueo: $horaInicio - $horaFin',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vuelve cuando termine el bloqueo 🦝' ,
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}