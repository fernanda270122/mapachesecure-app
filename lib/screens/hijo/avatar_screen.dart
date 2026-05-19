import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  String? _avatarActual;

  final List<String> _avatares = [
    'assets/avatares/perfil1.jpeg',
    'assets/avatares/perfil2.jpeg',
    'assets/avatares/perfil3.jpeg',
    'assets/avatares/perfil4.jpeg',
    'assets/avatares/perfil6.jpeg',
    'assets/avatares/perfil7.jpeg',
    'assets/avatares/perfil8.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _cargarAvatar();
  }

  Future<void> _cargarAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarActual = prefs.getString('avatar_hijo');
    });
  }

  Future<void> _seleccionarAvatar(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_hijo', path);
    setState(() => _avatarActual = path);
    if (mounted) Navigator.pop(context, path);
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text('Elige tu avatar'),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: _avatares.length,
          itemBuilder: (context, index) {
            final path = _avatares[index];
            final seleccionado = path == _avatarActual;
            return GestureDetector(
              onTap: () => _seleccionarAvatar(path),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seleccionado ? Colors.deepPurple : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: AssetImage(path),
                  radius: 45,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}