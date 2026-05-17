import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:http/http.dart'
    as http; // Usamos http directo para el Multipart
import 'package:shared_preferences/shared_preferences.dart';

class VerificarIdentidadScreen extends StatefulWidget {
  const VerificarIdentidadScreen({super.key});

  @override
  State<VerificarIdentidadScreen> createState() =>
      _VerificarIdentidadScreenState();
}

class _VerificarIdentidadScreenState extends State<VerificarIdentidadScreen> {
  File? _imageFile;
  bool _enviando = false;
  final ImagePicker _picker = ImagePicker();

  // URL base de producción que obtuvimos de tu ApiService
  final String _baseUrl = 'https://mapachesecure-backend.onrender.com';

  // Captura la selfie con la cámara frontal
  Future<void> _tomarFotoRostro() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50, // Comatible con la compresión de tus desafíos
      );
      if (photo != null) {
        setState(() => _imageFile = File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir la cámara: $e')));
    }
  }

  // ENVÍO EN FORMATO MULTIPART (FORM-DATA) DIRECTO A FASTAPI
  Future<void> _enviarVerificacion() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Por favor, saca una foto de tu rostro!'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      // 1. Obtener los datos del usuario logueado en las SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('user_id') ?? 'sin_id';
      final String nombre = prefs.getString('user_nombre') ?? 'Usuario Mapache';
      final String email =
          prefs.getString('user_email') ?? 'correo@ejemplo.com';
      final String? token = prefs.getString('token');

      // 2. Crear la petición Multipart apuntando al endpoint de auth.py
      final url = Uri.parse('$_baseUrl/auth/verificar-identidad');
      final request = http.MultipartRequest('POST', url);

      // 3. Añadir las cabeceras de autorización
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // --- SOLUCIÓN AL ERROR DE DUPLICADO ---
      // Creamos un identificador único sumándole los milisegundos actuales al ID del usuario
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String unicoUserId = '${userId}_$timestamp';

      // 4. Adjuntar los campos de formulario esperados por FastAPI
      // Pasamos 'unicoUserId' en vez de 'userId' para engañar a Supabase con el nombre del archivo
      request.fields['user_id'] = unicoUserId;
      request.fields['nombre'] = nombre;
      request.fields['email'] = email;

      // 5. Adjuntar el archivo de la foto
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto', // Mismo nombre del parámetro en FastAPI
          _imageFile!.path,
        ),
      );

      // 6. Enviar la petición al servidor de Render
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 7. Evaluar la respuesta del backend
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('¡Foto enviada a revisión con éxito🦝'),
            ),
          );
        }
      } else {
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la verificación: $e')),
      );
    } finally {
      setState(() => _enviando = false);
    }
  }

  void _mostrarExplicacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Por qué verificamos tu rostro?'),
        content: const Text(
          'Utilizamos un análisis facial rápido para confirmar que eres mayor de edad y mantener un entorno seguro en Raccu. No compartiremos tu foto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildZonaCapturaRostro(),
              const SizedBox(height: 40),
              _buildBotonesAccion(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      centerTitle: true,
      title: const Text(
        'Verificación',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.face_unlock_rounded, size: 80, color: Colors.green),
        SizedBox(height: 24),
        Text(
          'Verificación de Rostro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 255, 255, 255),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Para proteger la comunidad de Raccu, necesitamos una selfie para verificar que eres mayor de edad.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 255, 255, 255),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildZonaCapturaRostro() {
    return GestureDetector(
      onTap: _enviando ? null : _tomarFotoRostro,
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 60,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Toca aquí para tomar la foto',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Asegúrate de que tu rostro se vea claramente y con buena luz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Column(
      children: [
        _enviando
            ? const CircularProgressIndicator(color: Colors.green)
            : ElevatedButton.icon(
                onPressed: _imageFile == null
                    ? _tomarFotoRostro
                    : _enviarVerificacion,
                icon: Icon(
                  _imageFile == null
                      ? Icons.camera_alt_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _imageFile == null
                      ? 'Escanear Rostro'
                      : 'Enviar para Verificación',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                ),
              ),
        const SizedBox(height: 15),
        if (_imageFile != null && !_enviando) ...[
          TextButton.icon(
            onPressed: _tomarFotoRostro,
            icon: const Icon(Icons.refresh, color: Colors.grey),
            label: const Text(
              'Tomar otra foto',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 5),
        ],
        TextButton(
          onPressed: _mostrarExplicacion,
          child: const Text(
            '¿Por qué necesitamos esto?',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
