import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart'; // Importamos tu paleta lila

class RecuperarPassword extends StatefulWidget {
  const RecuperarPassword({super.key});

  @override
  State<RecuperarPassword> createState() => _RecuperarPasswordState();
}

class _RecuperarPasswordState extends State<RecuperarPassword> {
  final _emailCtrl = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;

  // Obtenemos la paleta Lila Pastel idéntica a la del Login
  final paleta = AppPaletasPadre.paletas['Lila Pastel']!;

  Future<void> _enviar() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      await ApiService().post('/auth/recuperar-password', {
        'email': _emailCtrl.text.trim(),
      });
      setState(() => _enviado = true);
    } catch (e) {
      print('ERROR RECUPERAR PASSWORD: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Fondo base del Scaffold en el tono oscuro para fundirse abajo con el degradado
      backgroundColor: paleta.primary,
      appBar: AppBar(
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor:
            paleta.background, // El AppBar nace claro como el fondo superior
        foregroundColor:
            paleta.primary, // Texto del título en morado corporativo
        elevation: 0, // Quitamos la sombra para un look limpio y plano
      ),
      body: Container(
        // 2. Mismo degradado premium de la pantalla anterior
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [paleta.background, paleta.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 30.0,
            ),
            child: _enviado
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '¡Correo enviado! Revisa tu bandeja de entrada y sigue el link para crear una nueva contraseña.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: paleta.primary, // Texto claro e intuitivo
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // 3. Texto descriptivo en morado oscuro ya que está en la zona clara superior
                      Text(
                        'Ingresa tu correo y te enviaremos un link para recuperar tu contraseña.',
                        style: TextStyle(
                          color: paleta.primary.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 4. Input estilizado con fondo blanco sólido (10/10 en legibilidad)
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          prefixIcon: Icon(Icons.email, color: paleta.primary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: paleta.accent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: paleta.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 5. Botón principal con el color oscuro corporativo y texto en blanco
                      ElevatedButton(
                        onPressed: _cargando ? null : _enviar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paleta.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'ENVIAR CORREO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
