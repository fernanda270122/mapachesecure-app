import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'recuperar_password.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables de estado
  bool _cargando = false;
  String? _error;

  // Función principal para el inicio de sesión
  Future<void> _login() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final authService = AuthService();

      final respuesta = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      // Extrae el rol del perfil para decidir a qué pantalla navegar
      final rol = respuesta['perfil']['rol'];
      final usuarioId = respuesta['user_id'].toString();
      final token = respuesta['access_token'];

      // ── GUARDAMOS LOS DATOS PARA EL GUARDIÁN EN SEGUNDO PLANO ──
      final prefs = await SharedPreferences.getInstance();

      if (token != null) {
        await prefs.setString('auth_token', token.toString());
      }

      // Dependiendo tu rol te lleva a tu home correspondiente
      if (rol == 'padre') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePadreScreen()),
        );
      } else {
        await prefs.setString('hijo_id', usuarioId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeHijoScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Correo o contraseña incorrectos';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/racculogo.png', height: 150)),
              const SizedBox(height: 10),
              const Text(
                'Iniciar Sesion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),

              // email
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Correo electronico',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // contraseña
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Contrasena',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Boton de Ingreso
              ElevatedButton(
                onPressed: _cargando ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'INGRESAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 10),

              // Muestra el mensaje de error solo si la variable _error no es nula
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 15),

              // boton de registro
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CREAR CUENTA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // para recuperar la contraseña
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecuperarPassword(),
                    ),
                  );
                },
                child: const Text(
                  'Olvide mi contrasena',
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
