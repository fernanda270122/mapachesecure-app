import 'package:flutter/material.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  String _rolSeleccionado = 'Padre'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Text(
              'Crea tu cuenta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Únete a la familia MapacheSecure',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _buildTextField('Nombre Completo', Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField('Correo Electrónico', Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField('Contraseña', Icons.lock_outline, obscure: true),

            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '¿Quién usará la cuenta?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // Selección de Rol
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Padre'),
                    value: 'Padre',
                    groupValue: _rolSeleccionado,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _rolSeleccionado = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Hijo'),
                    value: 'Hijo',
                    groupValue: _rolSeleccionado,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _rolSeleccionado = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                // Aquí irá el registro en Firebase después
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}
