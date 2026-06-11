import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/services/notification_service.dart';
import 'recuperar_password.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart';

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

  // Obtenemos la paleta Lila Pastel directamente desde tu clase de configuración
  final paleta = AppPaletasPadre.paletas['Lila Pastel']!;

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

      final rol = respuesta['perfil']['rol'];
      final nombre = respuesta['perfil']['nombre'] ?? '';
      final usuarioId = respuesta['user_id'].toString();
      final token = respuesta['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _emailController.text);

      if (token != null) {
        await prefs.setString('auth_token', token.toString());
      }

      await NotificationService().registrarToken();
      await NotificationService().mostrarNotificacionLogin(nombre, rol);

      if (rol != 'padre') {
        await prefs.setString('hijo_id', usuarioId);
      }

      final Widget homeScreen = rol == 'padre'
          ? const HomePadreScreen()
          : const HomeHijoScreen();

      final onboardingVisto =
          prefs.getBool('onboarding_${usuarioId}_${rol}_visto') ?? false;

      final Widget destino = onboardingVisto
          ? homeScreen
          : OnboardingScreen(rol: rol, destino: homeScreen, userId: usuarioId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
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
          backgroundColor: paleta.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text(
                "Autorización Requerida",
                style: TextStyle(
                  color: paleta.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Para desactivar el Guardián, un adulto debe ingresar sus credenciales de acceso.",
                style: TextStyle(color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Correo del Adulto",
                  labelStyle: TextStyle(color: paleta.primary),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: paleta.primary.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(color: paleta.primary),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: paleta.primary.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: paleta.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: validando
                  ? null
                  : () async {
                      setState(() => validando = true);

                      try {
                        final authService = AuthService();
                        final respuesta = await authService.login(
                          emailController.text.trim(),
                          passController.text,
                        );

                        if (respuesta['perfil']['rol'] == 'padre') {
                          final prefs = await SharedPreferences.getInstance();
                          final onboardingKeys = prefs
                              .getKeys()
                              .where((k) => k.startsWith('onboarding_'))
                              .toList();
                          final savedFlags = {
                            for (var k in onboardingKeys) k: prefs.getBool(k),
                          };
                          await prefs.clear();
                          for (final entry in savedFlags.entries) {
                            if (entry.value != null) {
                              await prefs.setBool(entry.key, entry.value!);
                            }
                          }

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
      backgroundColor: paleta.primary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [paleta.background, paleta.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 60.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/racculogo.png', height: 150)),
                const SizedBox(height: 10),
                Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: paleta
                        .primary, // 1. MORADO CORPORATIVO (Perfecto sobre fondo claro)
                  ),
                ),
                const SizedBox(height: 20),

                // email
                TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.black87,
                  ), // 2. GRIS CASI NEGRO (Legibilidad máxima en inputs)
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: paleta.accent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: paleta.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // contraseña
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.black87),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: paleta.accent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: paleta.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Boton de Ingreso
                ElevatedButton(
                  onPressed: _cargando ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paleta.primary,
                    foregroundColor: Colors
                        .white, // 3. BLANCO ABSOLUTO (Destaca genial sobre el botón oscuro)
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'INGRESAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 15),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors
                            .redAccent, // 4. ROJO ALERTA ENÉRGICO (No se pierde con el lila)
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Boton de registro
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
                    backgroundColor: paleta.accent,
                    foregroundColor: paleta
                        .primary, // 5. MORADO CORPORATIVO (La mejor opción contrastando el botón claro)
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CREAR CUENTA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: paleta
                          .primary, // Forzado para un acabado super premium
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Para recuperar la contraseña
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
                    'Olvidé mi contraseña',
                    style: TextStyle(
                      color: Colors
                          .white70, // 6. BLANCO SUAVE (Brilla limpio sin saturar el fondo oscuro final)
                      fontWeight: FontWeight.w600,
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
