import 'package:flutter/material.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'recuperar_password.dart';

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

      // Dependiendo tu rol te lleva a tu home correspondiente
      if (rol == 'padre') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePadreScreen()),
        );
      } else {
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Center(
                child: Image.asset(
                  'assets/logo3.png',
                  height:150,
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Iniciar Sesion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),

            // email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Correo electronico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Contrasena',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Boton de Ingreso
            ElevatedButton(
              onPressed: _cargando ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
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
                backgroundColor: const Color(0xFFE9ECEF),
                foregroundColor: Colors.black,
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

            // para recuperar la contraseña(de momento no sirve de nada, pero ahi esta)
            TextButton(
              onPressed: () {
                Navigator.push(                                                                                                                                                                                 context,
                  MaterialPageRoute(builder: (context) => const RecuperarPassword()),                                                                                                                         );
              },
              child: const Text(
                'Olvide mi contrasena',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Iniciar como:', textAlign: TextAlign.center),
            const SizedBox(height: 15),

            // no los borren pls, los uso para cambiar de padre a hijo y vicebersa
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePadreScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Padre / Tutor',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeHijoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Hijo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}