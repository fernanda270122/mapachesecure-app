import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapachesecure_app/screens/auth/verificar_identidad_sreen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/theme/app_background.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Aquí guardo lo que el usuario escribe para que no se me pierda nada
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  // Variables para saber si algo falló o si todavía estamos esperando al servidor
  DateTime? _fechaSeleccionada;
  bool _cargando = false;
  String? _error;

  // Esta función abre el calendario para que el usuario elija su cumple
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,

      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // la funcion del registro
  Future<void> _registro() async {
    
    if (_fechaSeleccionada == null) {
      setState(() => _error = 'Por favor, ingresa tu fecha de nacimiento.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Primero lo mandamos a la pantalla de verificación para asegurar que todo sea real
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificarIdentidadScreen(),
          ),
        );
      }
    } catch (e) {
      // Si algo sale mal con el cambio de pantalla, aquí lo atrapamos
    }

    try {
      // Llamo a mi servicio de autenticación y le paso todos los datos que juntamos
      final authService = AuthService();
      await authService.registro(
        _emailController.text,
        _passwordController.text,
        _nombreController.text,
        _fechaSeleccionada!
            .toIso8601String(), // La fecha va en formato de base de datos
      );

      // Si todo salió bien, lo mando directo al Login para que estrene su cuenta
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Si el servidor se pone pesado o hay un error, le mostramos este mensaje
      setState(() {
        _error = 'Error al crear la cuenta. Intenta de nuevo.';
      });
    } finally {
      // Pase lo que pase, dejamos de mostrar el circulito de carga
      setState(() {
        _cargando = false;
      });
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
          child: SingleChildScrollView(                                                                                                                                                                 padding: EdgeInsets.fromLTRB(30, kToolbarHeight + 40, 30, 30),
            child: Column(                                                                                                                                                                              children: [
              // El título llamativo de la pantalla
              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Únete a la familia Raccu',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                'Nombre Completo',
                Icons.person_outline,
                controller: _nombreController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Correo Electrónico',
                Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Contraseña',
                Icons.lock_outline,
                obscure: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _fechaController,
                readOnly: true,
                onTap: () => _seleccionarFecha(context),
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  prefixIcon: const Icon(Icons.cake_outlined, color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _cargando ? null : _registro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrarse', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
            ),
          ),
        ),
    );
  }

  // Esta es mi "fábrica" de campos de texto, para que todos se vean igual de bien
  Widget _buildTextField(
    String label,
    IconData icon, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}
