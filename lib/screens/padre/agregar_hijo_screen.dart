import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/providers/tema_padre_provider.dart'; // <-- AÑADIDO
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

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
    'creativo',
    'sociable',
  ];
  static const _opcionesIntereses = [
    'deportes',
    'música',
    'lectura',
    'arte',
    'tecnología',
    'naturaleza',
    'cocina',
    'videojuegos',
    'ciencias',
    'manualidades',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  static const _apkUrl =
      'https://drive.google.com/uc?export=download&confirm=t&id=165E8JxUPEHuUICXvlcBvoFHlkjMreR8c';

  void _mostrarQR(BuildContext context, String nombreHijo, Color colorBoton) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¡$nombreHijo está ${_sexo == "femenino" ? "lista" : "listo"}! 🦝'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Que escanee este código QR con su celular para descargar la app:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Image.asset('assets/raccu_qr.png', width: 200, height: 200),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.copy, size: 16, color: colorBoton),
              label: Text('Copiar link', style: TextStyle(color: colorBoton)),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _apkUrl));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copiado')));
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorBoton),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Listo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarHijo(Color colorBoton) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final api = ApiService();
      final respuesta = await api.post('/auth/registro-hijo', {
        'nombre': _nombreCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'edad': int.parse(_edadCtrl.text),
        if (_sexo != null) 'sexo': _sexo,
        if (_nivelEscolar != null) 'nivel_escolar': _nivelEscolar,
        if (_personalidad != null) 'personalidad': _personalidad,
        if (_interesesSeleccionados.isNotEmpty)
          'intereses': _interesesSeleccionados,
      });

      if (!mounted) return;
      setState(() => _cargando = false);

      if (respuesta['mensaje'] != null) {
        _mostrarQR(context, _nombreCtrl.text.trim(), colorBoton);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta['detail'] ?? 'Error al agregar hijo/a'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el tema exclusivo del padre
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Agregar Hijo/a',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Aplicamos el degradado dinámico al 0.62 que quedó perfecto
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // --- Datos de cuenta ---
                _seccionTitulo('Datos de acceso'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: _inputDecor(
                    'Nombre del hijo/a',
                    Icons.person,
                    temaPadre.primary,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: _inputDecor(
                    'Correo electrónico',
                    Icons.email,
                    temaPadre.primary,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa el correo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: _inputDecor(
                    'Contraseña',
                    Icons.lock,
                    temaPadre.primary,
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _edadCtrl,
                  decoration: _inputDecor(
                    'Edad',
                    Icons.cake,
                    temaPadre.primary,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa la edad' : null,
                ),

                const SizedBox(height: 28),

                // --- Perfil del hijo ---
                _seccionTitulo('Perfil del hijo/a'),
                const SizedBox(height: 12),

                _dropdownField(
                  label: 'Sexo',
                  icon: Icons.wc,
                  value: _sexo,
                  opciones: _opcionesSexo,
                  onChanged: (v) => setState(() => _sexo = v),
                  colorBordeFocus: temaPadre.primary,
                ),
                const SizedBox(height: 16),

                _dropdownField(
                  label: 'Nivel escolar',
                  icon: Icons.school,
                  value: _nivelEscolar,
                  opciones: _opcionesNivel,
                  onChanged: (v) => setState(() => _nivelEscolar = v),
                  colorBordeFocus: temaPadre.primary,
                ),
                const SizedBox(height: 16),

                _dropdownField(
                  label: 'Personalidad',
                  icon: Icons.psychology,
                  value: _personalidad,
                  opciones: _opcionesPersonalidad,
                  onChanged: (v) => setState(() => _personalidad = v),
                  colorBordeFocus: temaPadre.primary,
                ),

                const SizedBox(height: 28),

                // --- Intereses ---
                _seccionTitulo('Intereses'),
                const SizedBox(height: 4),
                const Text(
                  'Selecciona lo que mas les gusta a tus hijos/as',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _opcionesIntereses.map((interes) {
                    final seleccionado = _interesesSeleccionados.contains(
                      interes,
                    );
                    return FilterChip(
                      label: Text(interes),
                      selected: seleccionado,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _interesesSeleccionados.add(interes);
                          } else {
                            _interesesSeleccionados.remove(interes);
                          }
                        });
                      },
                      // Modificado para usar colores de tu paleta o estados más limpios
                      selectedColor: temaPadre.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.6),
                      labelStyle: TextStyle(
                        color: seleccionado ? Colors.white : Colors.black87,
                        fontWeight: seleccionado
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: seleccionado
                              ? temaPadre.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cargando
                        ? null
                        : () => _agregarHijo(temaPadre.primary),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          temaPadre.primary, // <-- AHORA USA TU COLOR PRIMARIO
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Agregar Hijo/a',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87, // Cambiado a oscuro para un contraste limpio
      ),
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
      value: value,
      dropdownColor: Colors.white,
      decoration: _inputDecor(label, icon, colorBordeFocus),
      items: opciones
          .map((o) => DropdownMenuItem(value: o, child: Text(_capitalizar(o))))
          .toList(),
      onChanged: onChanged,
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  InputDecoration _inputDecor(String label, IconData icon, Color colorFocus) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: colorFocus),
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorFocus, width: 2),
      ),
    );
  }
}
