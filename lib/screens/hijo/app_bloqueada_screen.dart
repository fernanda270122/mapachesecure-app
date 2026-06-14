import 'package:flutter/material.dart';

class AppBloqueadaScreen extends StatelessWidget {
  final String nombreAppIntentada;

  const AppBloqueadaScreen({super.key, required this.nombreAppIntentada});

  @override
  Widget build(BuildContext context) {
    // 👇 ENVOLVEMOS TODO EN POPSCOPE 👇
    return PopScope(
      canPop: false, // 🚫 Prohíbe salir de esta pantalla con el botón "atrás"
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Aquí podrías mostrar un mensaje si quisieras,
        // pero lo ideal es no hacer nada para que se quede bloqueado.
        debugPrint("Intento de salida bloqueado por Raccu 🦝");
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFB71C1C), // Rojo intenso de advertencia
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                const Text(
                  '¡ALTO AHÍ!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'El acceso a $nombreAppIntentada ha sido restringido por tus padres.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    // Al presionar esto, lo mandamos al Home del hijo en Raccu
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home-hijo', // Asegúrate de tener esta ruta en tu main.dart
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('VOLVER A RACCU'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFB71C1C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
