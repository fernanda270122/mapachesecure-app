import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Función para capturar la foto
  Future<void> _tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (photo != null) {
      setState(() => _evidencia = File(photo.path));
    }
  }

  // Función para enviar al backend
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
      // NOTA: Aquí debes usar MultipartRequest si tu backend FastAPI espera un archivo
      // Por ahora, simulamos el envío exitoso al endpoint de completar
      await api.post('/desafios/completar/', {
        'desafio_id': widget.desafio['id'],
        'hijo_id': widget.desafio['hijo_id'], // Asegúrate de pasar esto
      });

      if (mounted) {
        Navigator.pop(context, true); // Retornamos true para refrescar la lista
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.desafio['titulo'] ?? 'Resolver Desafío'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card de instrucción
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.desafio['descripcion'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recompensa: ${widget.desafio['puntos']} pts',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Preview de la imagen
            GestureDetector(
              onTap: _tomarFoto,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: _evidencia == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: AppColors.primary,
                          ),
                          Text('Toca para sacar la foto de evidencia'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_evidencia!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 40),

            _enviando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _enviarEvidencia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'ENVIAR DESAFÍO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
