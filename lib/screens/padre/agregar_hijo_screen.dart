import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
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
  static const _opcionesPersonalidad = ['curioso', 'activo', 'tranquilo', 'creativo', 'sociable'];
  static const _opcionesIntereses = [
    'deportes', 'música', 'lectura', 'arte', 'tecnología',
    'naturaleza', 'cocina', 'videojuegos', 'ciencias', 'manualidades'
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  static const _apkUrl = 'https://drive.google.com/uc?export=download&id=165E8JxUPEHuUICXvlcBvoFHlkjMreR8c';

  void _mostrarQR(BuildContext context, String nombreHijo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¡$nombreHijo está listo! 🦝'),
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
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar link'),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _apkUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado')),
                );
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
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

  Future<void> _agregarHijo() async {
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
        if (_interesesSeleccionados.isNotEmpty) 'intereses': _interesesSeleccionados,
      });

      if (!mounted) return;
      setState(() => _cargando = false);

      if (respuesta['mensaje'] != null) {
        _mostrarQR(context, _nombreCtrl.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta['detail'] ?? 'Error al agregar hijo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agregar Hijo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppBackground(child: SingleChildScrollView(
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
                decoration: _inputDecor('Nombre del hijo', Icons.person),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDecor('Correo electrónico', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa el correo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: _inputDecor('Contraseña', Icons.lock),
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _edadCtrl,
                decoration: _inputDecor('Edad', Icons.cake),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa la edad' : null,
              ),

              const SizedBox(height: 28),

              // --- Perfil del hijo ---
              _seccionTitulo('Perfil del hijo'),
              const SizedBox(height: 12),

              _dropdownField(
                label: 'Sexo',
                icon: Icons.wc,
                value: _sexo,
                opciones: _opcionesSexo,
                onChanged: (v) => setState(() => _sexo = v),
              ),
              const SizedBox(height: 16),

              _dropdownField(
                label: 'Nivel escolar',
                icon: Icons.school,
                value: _nivelEscolar,
                opciones: _opcionesNivel,
                onChanged: (v) => setState(() => _nivelEscolar = v),
              ),
              const SizedBox(height: 16),

              _dropdownField(
                label: 'Personalidad',
                icon: Icons.psychology,
                value: _personalidad,
                opciones: _opcionesPersonalidad,
                onChanged: (v) => setState(() => _personalidad = v),
              ),

              const SizedBox(height: 28),

              // --- Intereses ---
              _seccionTitulo('Intereses'),
              const SizedBox(height: 4),
              const Text(
                'Selecciona los que más le gustan al niño',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _opcionesIntereses.map((interes) {
                  final seleccionado = _interesesSeleccionados.contains(interes);
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
                    selectedColor: AppColors.card.withOpacity(0.5),
                    checkmarkColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: seleccionado ? AppColors.white: AppColors.white,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _agregarHijo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Agregar Hijo', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      )),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> opciones,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecor(label, icon),
      items: opciones
          .map((o) => DropdownMenuItem(value: o, child: Text(_capitalizar(o))))
          .toList(),
      onChanged: onChanged,
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.white),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
    );
  }
}
