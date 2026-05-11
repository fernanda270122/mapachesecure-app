import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

class DetalleDesafioScreen extends StatefulWidget {
  final Map<String, dynamic> desafio;

  const DetalleDesafioScreen({super.key, required this.desafio});

  @override
  State<DetalleDesafioScreen> createState() => _DetalleDesafioScreenState();
}

class _DetalleDesafioScreenState extends State<DetalleDesafioScreen> {
  File? _evidencia;
  bool _enviando = false;
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _configurarTts();
  }

  // Configuración del motor de voz
  Future<void> _configurarTts() async {
    await _flutterTts.setLanguage("es-CL"); // Acento chileno
    await _flutterTts.setSpeechRate(0.5); // Velocidad pausada para niños
    await _flutterTts.setPitch(1.0); // Tono amigable
  }

  // Función para activar la voz
  Future<void> _hablarInstrucciones() async {
    String texto = widget.desafio['descripcion'] ?? '';
    if (texto.isNotEmpty) {
      await _flutterTts.speak(texto);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Detener el audio si el niño sale de la pantalla
    super.dispose();
  }

  // Captura de evidencia
  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (photo != null) {
      setState(() => _evidencia = File(photo.path));
    }
  }

  // Envío al backend
  Future<void> _enviarEvidencia() async {
    if (_evidencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Saca una foto para demostrar que cumpliste!'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final api = ApiService();
      await api.post('/desafios/completar/', {
        'desafio_id': widget.desafio['id'],
        'hijo_id': widget.desafio['hijo_id'],
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('¡Desafío enviado al jefe! 🦝'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    } finally {
      setState(() => _enviando = false);
    }
  }

  Color _getDificultadColor(String? dificultad) {
    switch (dificultad?.toLowerCase()) {
      case 'facil':
      case 'fácil':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'dificil':
      case 'difícil':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.desafio['titulo'] ?? 'Resolver Desafío'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // TARJETA DE INSTRUCCIÓN
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // Usamos el color de la dificultad con un poco de transparencia
                        color: _getDificultadColor(
                          widget.desafio['dificultad'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getDificultadColor(
                            widget.desafio['dificultad'],
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'NIVEL: ${(widget.desafio['dificultad'] ?? 'NORMAL').toUpperCase()}',
                        style: TextStyle(
                          color: _getDificultadColor(
                            widget.desafio['dificultad'],
                          ),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // TEXTO DE LA MISIÓN
                    Text(
                      widget.desafio['descripcion'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 25),

                    // RECOMPENSA Y ALTAVOZ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PUNTOS
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Recompensa: ${widget.desafio['puntos']} pts',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        // BOTÓN DE ALTAVOZ
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.volume_up_rounded),
                            color: AppColors.primary,
                            iconSize: 28,
                            onPressed: _hablarInstrucciones,
                            tooltip: 'Escuchar la misión',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // CONTENEDOR DE CÁMARA / EVIDENCIA
            GestureDetector(
              onTap: _tomarFoto,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _evidencia == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 55,
                            color: AppColors.primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 10),
                          const Text('Toca para sacar la foto de evidencia'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_evidencia!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // BOTÓN DE ENVÍO FINAL
            _enviando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _enviarEvidencia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'ENVIAR DESAFÍO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
