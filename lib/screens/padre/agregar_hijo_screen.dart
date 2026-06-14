import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // <-- AÑADIDO PARA LA ADAPTABILIDAD
import 'package:provider/provider.dart'; // <-- MANTENIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- MANTENIDO
import 'package:mapachesecure_app/services/api_service.dart';

class AgregarHijoScreen extends StatefulWidget {
  const AgregarHijoScreen({super.key});

  @override
  State<AgregarHijoScreen> createState() => _AgregarHijoScreenState();
}

class _AgregarHijoScreenState extends State<AgregarHijoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  bool _cargando = false;

  String? _sexo;
  String? _nivelEscolar;
  String? _personalidad;
  final List<String> _interesesSeleccionados = [];

  static const _opcionesSexo = ['masculino', 'femenino', 'otro'];
  static const _opcionesNivel = ['pre-basica', 'basica', 'media'];
  static const _opcionesPersonalidad = [
    'curioso/a',
    'activo/a',
    'tranquilo/a',
    'creativo/a',
    'tecnológico/a',
  ];
  static const _opcionesIntereses = [
    'videojuegos',
    'deportes',
    'música',
    'dibujo/arte',
    'ciencia',
    'lectura',
    'tecnología',
    'películas',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      final api = ApiService();
      await api.post('/auth/registro-hijo', {
        'nombre': _nombreCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'edad': int.parse(_edadCtrl.text.trim()),
        'sexo': _sexo,
        'nivel_escolar': _nivelEscolar,
        'personalidad': _personalidad,
        'intereses': _interesesSeleccionados,
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '¡Hijo registrado!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_nombreCtrl.text.trim()} ya tiene su cuenta en Raccu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Muéstrale este QR para que descargue la app:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/raccu_qr.png', height: 180),
              ),
              const SizedBox(height: 8),
              const Text(
                'También le llegará un correo de bienvenida con el enlace de descarga.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      String mensaje = 'Error al registrar. Intenta de nuevo.';
      final msg = e.toString();
      if (msg.contains('400')) {
        mensaje = 'El correo ya está registrado';
      } else if (msg.contains('429') || msg.toLowerCase().contains('rate limit') || msg.contains('limite')) {
        mensaje = 'Se alcanzó el límite de correos por hora. Intenta de nuevo en unos minutos.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: Text(
          'Agregar Hij@',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom:
            true, // 🛡️ Garantiza que el botón inferior no choque con la barra de gestos
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(temaPadre.primary, Colors.white, 0.62)!,
                temaPadre.background,
              ],
            ),
          ),
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(
                      20.r,
                    ), // Padding adaptativo del contenedor principal
                    children: [
                      Text(
                        'Datos de Cuenta',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      _inputField(
                        label: 'Nombre Completo',
                        icon: Icons.person,
                        controller: _nombreCtrl,
                        colorBordeFocus: temaPadre.primary,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Ingresa el nombre' : null,
                      ),
                      SizedBox(height: 12.h),

                      _inputField(
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                        controller: _emailCtrl,
                        keyboard: TextInputType.emailAddress,
                        colorBordeFocus: temaPadre.primary,
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Ingresa el correo';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),

                      _inputField(
                        label: 'Contraseña',
                        icon: Icons.lock,
                        controller: _passwordCtrl,
                        isPassword: true,
                        colorBordeFocus: temaPadre.primary,
                        validator: (v) =>
                            v!.trim().length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      SizedBox(height: 24.h),

                      Text(
                        'Perfil del Menor',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      _inputField(
                        label: 'Edad',
                        icon: Icons.cake,
                        controller: _edadCtrl,
                        keyboard: TextInputType.number,
                        colorBordeFocus: temaPadre.primary,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Ingresa la edad';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0 || n > 18) {
                            return 'Edad debe ser entre 1 y 18 años';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),

                      _dropdownField(
                        label: 'Sexo',
                        icon: Icons.wc,
                        value: _sexo,
                        opciones: _opcionesSexo,
                        colorBordeFocus: temaPadre.primary,
                        onChanged: (val) => setState(() => _sexo = val),
                      ),
                      SizedBox(height: 12.h),

                      _dropdownField(
                        label: 'Nivel Escolar',
                        icon: Icons.school,
                        value: _nivelEscolar,
                        opciones: _opcionesNivel,
                        colorBordeFocus: temaPadre.primary,
                        onChanged: (val) => setState(() => _nivelEscolar = val),
                      ),
                      SizedBox(height: 12.h),

                      _dropdownField(
                        label: 'Personalidad',
                        icon: Icons.psychology,
                        value: _personalidad,
                        opciones: _opcionesPersonalidad,
                        colorBordeFocus: temaPadre.primary,
                        onChanged: (val) => setState(() => _personalidad = val),
                      ),
                      SizedBox(height: 20.h),

                      Text(
                        'Intereses / Gustos',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: _opcionesIntereses.map((interes) {
                          final selec = _interesesSeleccionados.contains(
                            interes,
                          );
                          return FilterChip(
                            label: Text(_capitalizar(interes)),
                            selected: selec,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _interesesSeleccionados.add(interes);
                                } else {
                                  _interesesSeleccionados.remove(interes);
                                }
                              });
                            },
                            selectedColor: temaPadre.primary.withValues(alpha: 0.2),
                            checkmarkColor: temaPadre.primary,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              side: BorderSide(
                                color: selec
                                    ? temaPadre.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: selec ? temaPadre.primary : Colors.grey,
                              fontWeight: selec
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13.sp,
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 30.h),

                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: temaPadre.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Registrar e Iniciar',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color colorBordeFocus,
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      decoration: _inputDecor(label, icon, colorBordeFocus),
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> opciones,
    required void Function(String?) onChanged,
    required Color colorBordeFocus,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.white,
      decoration: _inputDecor(label, icon, colorBordeFocus),
      items: opciones
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(_capitalizar(o), style: TextStyle(fontSize: 14.sp)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  InputDecoration _inputDecor(String label, IconData icon, Color colorFocus) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black54, fontSize: 13.sp),
      prefixIcon: Icon(icon, color: colorFocus, size: 20.r),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: colorFocus, width: 2.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
