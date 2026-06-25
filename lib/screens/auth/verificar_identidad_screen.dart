import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart'
    as http; // Usamos http directo para el Multipart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart'; // Tu paleta unificada

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

  // URL base de producción
  final String _baseUrl = 'https://mapachesecure-backend.onrender.com';

  // Obtenemos la paleta Lila Pastel idéntica a las pantallas anteriores
  final paleta = AppPaletasPadre.paletas['Lila Pastel']!;

  // Captura la selfie con la cámara frontal
  Future<void> _tomarFotoRostro() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );
      if (photo != null) {
        setState(() => _imageFile = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir la cámara: $e')));
    }
  }

  // ENVÍO EN FORMATO MULTIPART (FORM-DATA) DIRECTO A FASTAPI
  Future<void> _enviarVerificacion() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: paleta.primary,
          content: const Text('¡Por favor, saca una foto de tu rostro!'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('user_id') ?? 'sin_id';
      final String nombre = prefs.getString('user_nombre') ?? 'Usuario Mapache';
      final String email =
          prefs.getString('user_email') ?? 'correo@ejemplo.com';
      final String? token = prefs.getString('token');

      final url = Uri.parse('$_baseUrl/auth/verificar-identidad');
      final request = http.MultipartRequest('POST', url);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String unicoUserId = '${userId}_$timestamp';

      request.fields['user_id'] = unicoUserId;
      request.fields['nombre'] = nombre;
      request.fields['email'] = email;

      request.files.add(
        await http.MultipartFile.fromPath('foto', _imageFile!.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      if (!mounted) return;
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
        backgroundColor: Colors.white,
        title: Text(
          '¿Por qué verificamos tu rostro?',
          style: TextStyle(color: paleta.primary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Utilizamos un análisis facial rápido para confirmar que eres mayor de edad y mantener un entorno seguro en Raccu. No compartiremos tu foto.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(
                color: paleta.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo base oscuro para fusionar la barra inferior
      backgroundColor: paleta.primary,
      appBar: _buildAppBar(context),
      body: Container(
        // Aplicamos el degradado fluido idéntico a las pantallas anteriores
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [paleta.background, paleta.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 35),
                _buildZonaCapturaRostro(),
                const SizedBox(height: 35),
                _buildBotonesAccion(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          paleta.background, // Nace claro igual que el inicio del degradado
      centerTitle: true,
      title: Text(
        'Verificación',
        style: TextStyle(
          color: paleta.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: paleta.primary),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Cambiado el ícono verde por el morado de marca con una sutil sombra blanca
        Icon(Icons.face_unlock_rounded, size: 80, color: paleta.primary),
        const SizedBox(height: 24),
        Text(
          'Verificación de Rostro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: paleta.primary, // Morado corporativo para la zona clara
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Para proteger la comunidad de Raccu, necesitamos una selfie para verificar que eres mayor de edad.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: paleta.primary.withValues(
              alpha: 0.8,
            ), // Texto legible sobre fondo claro
            height: 1.4,
            fontWeight: FontWeight.w500,
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
          color: Colors.white.withValues(
            alpha: 0.9,
          ), // Fondo blanco semi-sólido premium
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: paleta.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 60,
                      color: paleta.primary, // Icono unificado
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toca aquí para tomar la foto',
                      style: TextStyle(
                        color: paleta.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Asegúrate de que tu rostro se vea claramente y con buena luz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors
                            .black54, // Legibilidad óptima sobre el recuadro blanco
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
            ? CircularProgressIndicator(color: paleta.accent)
            : ElevatedButton.icon(
                onPressed: _imageFile == null
                    ? _tomarFotoRostro
                    : _enviarVerificacion,
                icon: Icon(
                  _imageFile == null
                      ? Icons.camera_alt_rounded
                      : Icons.check_circle_rounded,
                  color:
                      paleta.primary, // Texto e ícono morado sobre botón lila
                ),
                label: Text(
                  _imageFile == null
                      ? 'Escanear Rostro'
                      : 'Enviar para Verificación',
                  style: TextStyle(
                    color: paleta.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: paleta
                      .accent, // Botón dinámico brillante en zona baja oscura
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
        const SizedBox(height: 15),
        if (_imageFile != null && !_enviando) ...[
          TextButton.icon(
            onPressed: _tomarFotoRostro,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: const Text(
              'Tomar otra foto',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
        TextButton(
          onPressed: _mostrarExplicacion,
          child: Text(
            '¿Por qué necesitamos esto?',
            style: TextStyle(
              color: paleta
                  .accent, // Resalta en blanco/lila suave en la zona inferior
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
