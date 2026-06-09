
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';

class SeleccionAvatarScreen extends StatefulWidget {
  const SeleccionAvatarScreen({super.key});

  @override
  State<SeleccionAvatarScreen> createState() => _SeleccionAvatarScreenState();
}

class _SeleccionAvatarScreenState extends State<SeleccionAvatarScreen> {
  int _indice = 0;
  VideoPlayerController? _controller;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _cargarVideo(_indice);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _cargarVideo(int indice) async {
    setState(() => _inicializado = false);

    final anterior = _controller;
    anterior?.pause();

    final avatar = AvatarTypes.todos[indice];
    final controller = VideoPlayerController.asset(avatar.videoPath!);
    await controller.initialize();
    await controller.setLooping(true);

    if (!mounted) {
      controller.dispose();
      return;
    }

    await anterior?.dispose();

    setState(() {
      _controller = controller;
      _inicializado = true;
    });

    await controller.play();
  }

  void _irA(int indice) {
    if (indice < 0 || indice >= AvatarTypes.todos.length) return;
    _indice = indice;
    _cargarVideo(_indice);
  }

  void _elegir() {
    Navigator.pop(context, AvatarTypes.todos[_indice].id);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarTypes.todos[_indice];
    final total = AvatarTypes.todos.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video de fondo
          if (_inicializado && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Degradado superior para el texto
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Degradado inferior para los botones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // Título arriba
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¡Elige tu compañero!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      avatar.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Flechas de navegación (centradas verticalmente)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: _indice > 0 ? () => _irA(_indice - 1) : null,
                ),
                _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: _indice < total - 1 ? () => _irA(_indice + 1) : null,
                ),
              ],
            ),
          ),

          // Dots + botón abajo
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots indicadores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final activo = i == _indice;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: activo ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activo
                                ? const Color(0xFFFFD700)
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Botón elegir
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _inicializado ? _elegir : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '¡ELEGIR A ${avatar.nombre.toUpperCase()}!',
                          style: const TextStyle(
                            color: Color(0xFF0D0D1A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: double.infinity,
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: onTap != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
