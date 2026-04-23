import 'package:flutter/material.dart';
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

@override
void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
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
    });

    if (!mounted) return;

    if (respuesta['mensaje'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hijo agregado exitosamente'),
            backgroundColor: Colors.green,
        ),
        );
        Navigator.pop(context, true);
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(respuesta['detail'] ?? 'Error al agregar hijo'),
            backgroundColor: Colors.red,
        ),
        );
    }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Error de conexión'),
        backgroundColor: Colors.red,
        ),
    );
    } finally {
    setState(() => _cargando = false);
    }
}

@override
Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: const Text('Agregar Hijo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
        key: _formKey,
        child: Column(
            children: [
            const SizedBox(height: 10),
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
            const SizedBox(height: 32),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                onPressed: _cargando ? null : _agregarHijo,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Agregar Hijo', style: TextStyle(fontSize: 16)),
                ),
            ),
            ],
        ),
        ),
    ),
    );
}

InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
    ),
    );
}
}