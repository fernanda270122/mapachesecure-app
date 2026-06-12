import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapachesecure_app/screens/auth/verificar_identidad_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/theme/app_paletas_padre.dart'; // Tu paleta unificada

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  // Variables de estado
  DateTime? _fechaSeleccionada;
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _cuota;

  // Obtenemos la paleta Lila Pastel idéntica a las pantallas anteriores
  final paleta = AppPaletasPadre.paletas['Lila Pastel']!;

  @override
  void initState() {
    super.initState();
    _cargarCuota();
  }

  // Consulta cuántos correos de confirmación quedan en la cuota gratuita de Supabase
  Future<void> _cargarCuota() async {
    try {
      final cuota = await AuthService().cuotaCorreos();
      if (mounted) setState(() => _cuota = cuota);
    } catch (_) {
      // Si el endpoint no responde, simplemente no se muestra el contador
    }
  }

  // Función para abrir el calendario
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Estilizamos el calendario para que use tus colores corporativos
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: paleta.primary, // Encabezado lila oscuro
              onPrimary: Colors.white, // Texto del encabezado
              onSurface: paleta.primary, // Días del calendario
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: paleta.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Lógica de registro
  Future<void> _registro() async {
    if (_passwordController.text != _confirmarPasswordController.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (_fechaSeleccionada == null) {
      setState(() => _error = 'Por favor, ingresa tu fecha de nacimiento.');
      return;
    }

    setState(() => _cargando = true);

    try {
      final auth = AuthService();
      await auth.registro(
        _emailController.text,
        _passwordController.text,
        _nombreController.text,
        'padre',
      );
      await auth.login(_emailController.text, _passwordController.text);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nombre', _nombreController.text);
      await prefs.setString('user_email', _emailController.text);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificarIdentidadScreen(),
          ),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingScreen(
                rol: 'padre',
                destino: const HomePadreScreen(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(
        () => _error =
            'Error al registrarse: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      // Refresca el contador: si fue un 429, el backend ya detectó el límite
      _cargarCuota();
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo base oscuro para fusionar la barra inferior del sistema
      backgroundColor: paleta.primary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: paleta.primary,
          ), // Flecha a tono con el inicio claro
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        // Envoltura con el degradado fluido de la app
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
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Títulos en la zona clara (Morado corporativo)
                Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: paleta.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Únete a la familia Raccu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: paleta.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_cuota != null) _buildCuotaBanner(),
                const SizedBox(height: 35),

                // Campos de entrada con fondo blanco 10/10 en legibilidad
                _buildTextField(
                  'Nombre Completo',
                  Icons.person_outline,
                  controller: _nombreController,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  'Correo Electrónico',
                  Icons.email_outlined,
                  controller: _emailController,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  'Contraseña',
                  Icons.lock_outline,
                  obscure: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  'Confirmar Contraseña',
                  Icons.lock_outline,
                  obscure: true,
                  controller: _confirmarPasswordController,
                ),
                const SizedBox(height: 15),

                // Campo de fecha estilizado idéntico a los inputs anteriores
                TextField(
                  controller: _fechaController,
                  readOnly: true,
                  onTap: () => _seleccionarFecha(context),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Fecha de Nacimiento',
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    prefixIcon: Icon(
                      Icons.cake_outlined,
                      color: paleta.primary,
                    ),
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
                const SizedBox(height: 30),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Botón de Registrarse (Acción principal: Fondo claro corporativo con texto morado oscuro)
                ElevatedButton(
                  onPressed: _cargando ? null : _registro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paleta.accent,
                    foregroundColor: paleta.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _cargando
                      ? CircularProgressIndicator(color: paleta.primary)
                      : Text(
                          'REGISTRARSE',
                          style: TextStyle(
                            color: paleta.primary,
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

  // Contador de la cuota de correos de confirmación de Supabase (capa gratuita)
  Widget _buildCuotaBanner() {
    final enviados = _cuota!['enviados_ultima_hora'] ?? 0;
    final limite = _cuota!['limite'];
    final restantes = _cuota!['restantes'];
    final proximoCupo = _cuota!['proximo_cupo'];

    String texto;
    IconData icono = Icons.mark_email_read_outlined;
    Color color = paleta.primary;

    if (limite == null) {
      texto =
          'Correos de confirmación enviados esta hora: $enviados\n'
          'Límite de Supabase aún no detectado';
    } else if (restantes != null && restantes > 0) {
      texto = 'Correos de confirmación: $enviados de $limite usados esta hora';
    } else {
      icono = Icons.warning_amber_rounded;
      color = Colors.redAccent;
      String hora = '';
      if (proximoCupo != null) {
        final cupo = DateTime.parse(proximoCupo).toLocal();
        hora = ' Nuevo cupo a las ${DateFormat('HH:mm').format(cupo)}.';
      }
      texto = 'Límite de Supabase alcanzado ($limite por hora).$hora';
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: paleta.accent),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fábrica optimizada de campos de texto
  Widget _buildTextField(
    String label,
    IconData icon, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        prefixIcon: Icon(icon, color: paleta.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: paleta.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: paleta.primary, width: 2),
        ),
      ),
    );
  }
}
