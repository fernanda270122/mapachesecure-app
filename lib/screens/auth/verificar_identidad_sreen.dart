import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

class VerificarIdentidadScreen extends StatefulWidget {
  final String nombre;
  final String email;
  final String password;

  const VerificarIdentidadScreen({
    super.key,
    required this.nombre,
    required this.email,
    required this.password,
  });

  @override
  State<VerificarIdentidadScreen> createState() => _VerificarIdentidadScreenState();
}

class _VerificarIdentidadScreenState extends State<VerificarIdentidadScreen> {
  File? _foto;
  bool _cargando = false;
  String? _error;

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (picked != null) {
      setState(() => _foto = File(picked.path));
    }
  }

  Future<void> _enviarVerificacion() async {
    if (_foto == null) {
      setState(() => _error = 'Por favor toma una foto de tu identificación.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Paso 1: crear la cuenta
      final registroRes = await http.post(
        Uri.parse('https://mapachesecure-backend.onrender.com/auth/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
          'nombre': widget.nombre,
          'rol': 'padre',
        }),
      );

      if (registroRes.statusCode != 200) {
        setState(() => _error ='Status: ${registroRes.statusCode} - ${registroRes.body}');
        return;
      }

      final registroData = jsonDecode(registroRes.body);
      final userId = registroData['user_id'];

      // Paso 2: enviar foto y notificar al equipo
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://mapachesecure-backend.onrender.com/auth/verificar-identidad'),
      );
      request.fields['user_id'] = userId;
      request.fields['nombre'] = widget.nombre;
      request.fields['email'] = widget.email;
      request.files.add(await http.MultipartFile.fromPath('foto', _foto!.path));

      final verificarRes = await request.send();

      if (verificarRes.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('¡Solicitud enviada!'),
              content: const Text('Revisaremos tu identificación y activaremos tu cuenta pronto.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _error = 'Error al enviar la verificación. Intenta de nuevo.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(30, kToolbarHeight + 40, 30, 30),
          child: Column(
            children: [
              const Text(
                'Verificación de identidad',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Toma una foto de tu identificación para confirmar que eres mayor de edad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _tomarFoto,
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: _foto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(_foto!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 50, color: Colors.white54),
                            SizedBox(height: 10),
                            Text('Toca para tomar foto', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ElevatedButton(
                onPressed: _cargando ? null : _enviarVerificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar verificación', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}