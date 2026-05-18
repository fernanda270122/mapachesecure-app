import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/services/notification_service.dart';
import 'recuperar_password.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';

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
      final nombre = respuesta['perfil']['nombre'] ?? '';
      final usuarioId = respuesta['user_id'].toString();
      final token = respuesta['access_token'];

      // ── GUARDAMOS LOS DATOS PARA EL GUARDIÁN EN SEGUNDO PLANO ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _emailController.text);

      if (token != null) {
        await prefs.setString('auth_token', token.toString());
      }

      // Registra el token FCM ahora que ya hay sesión activa
      await NotificationService().registrarToken();

      // Notificación local de confirmación de inicio de sesión
      await NotificationService().mostrarNotificacionLogin(nombre, rol);

      // Dependiendo tu rol te lleva a tu home correspondiente
      if (rol != 'padre') {
        await prefs.setString('hijo_id', usuarioId);
      }

      final onboardingVisto = prefs.getBool('onboarding_${usuarioId}_${rol}_visto') ?? false;
      final destino = rol == 'padre'
          ? const HomePadreScreen()
          : const HomeHijoScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => onboardingVisto
              ? destino
              : OnboardingScreen(rol: rol, destino: destino),
        ),
      );
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

  void intentarCerrarSesion(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    bool validando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text(
                "Autorización Requerida",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Para desactivar el Guardián, un adulto debe ingresar sus credenciales de acceso.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Campo de Correo
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Correo del Adulto",
                  labelStyle: TextStyle(color: AppColors.accent),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 15),
              // Campo de Contraseña
              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(color: AppColors.accent),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              onPressed: validando
                  ? null
                  : () async {
                      setState(() => validando = true);

                      try {
                        final authService = AuthService();

                        // 1. Validamos las credenciales directamente con tu servicio
                        final respuesta = await authService.login(
                          emailController.text.trim(),
                          passController.text,
                        );

                        // 2. Verificamos que quien autoriza sea realmente un 'padre'
                        if (respuesta['perfil']['rol'] == 'padre') {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Limpiamos rastro del hijo

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } else {
                          throw Exception(
                            "Solo un adulto puede cerrar esta sesión",
                          );
                        }
                      } catch (e) {
                        setState(() => validando = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Credenciales inválidas o permiso denegado.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: validando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("DESACTIVAR GUARDIÁN"),
            ),
          ],
        ),
      ),
    );
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
