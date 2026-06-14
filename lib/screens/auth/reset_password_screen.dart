import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart'; // Tu paleta unificada

class ResetPasswordScreen extends StatefulWidget {
  final String accessToken;
  const ResetPasswordScreen({super.key, required this.accessToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _cargando = false;
  bool _listo = false;

  // Obtenemos la paleta Lila Pastel idéntica al resto del flujo
  final paleta = AppPaletasPadre.paletas['Lila Pastel']!;

  Future<void> _cambiar() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mínimo 6 caracteres')));
      return;
    }
    setState(() => _cargando = true);
    try {
      await ApiService().post('/auth/cambiar-password', {
        'access_token': widget.accessToken,
        'nueva_password': _passwordCtrl.text,
      });
      setState(() => _listo = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar la contraseña')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo base oscuro para fusionar la barra inferior de navegación
      backgroundColor: paleta.primary,
      appBar: AppBar(
        title: const Text(
          'Nueva contraseña',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor:
            paleta.background, // Se funde con el inicio claro del degradado
        foregroundColor: paleta.primary, // Texto morado corporativo
        elevation: 0, // Sin sombra divisoria defectuosa
      ),
      body: Container(
        // Degradado fluido idéntico a todo el ecosistema de la app
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
            child: _listo
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 50,
                            color: paleta.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Contraseña actualizada! Ya puedes iniciar sesión.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: paleta.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Texto descriptivo en la zona clara
                      Text(
                        'Crea una contraseña segura para proteger el acceso a tu cuenta.',
                        style: TextStyle(
                          color: paleta.primary.withValues(alpha: 0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Input 1: Nueva Contraseña con fondo premium
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Nueva contraseña',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          prefixIcon: Icon(Icons.lock, color: paleta.primary),
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
                      const SizedBox(height: 20),

                      // Input 2: Confirmar Contraseña
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Confirmar contraseña',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: paleta.primary,
                          ),
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
                      const SizedBox(height: 30),

                      // Botón Principal de acción (Fondo morado corporativo en la zona baja)
                      ElevatedButton(
                        onPressed: _cargando ? null : _cambiar,
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
                                'CAMBIAR CONTRASEÑA',
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
