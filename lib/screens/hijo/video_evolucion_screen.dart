import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoEvolucionScreen extends StatefulWidget {
  const VideoEvolucionScreen({super.key});

  @override
  State<VideoEvolucionScreen> createState() => _VideoEvolucionScreenState();
}

class _VideoEvolucionScreenState extends State<VideoEvolucionScreen> {
  late VideoPlayerController _controller;
  bool _inicializado = false;
  bool _mostrandoMensaje = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/mascota/mago.mp4');
    await _controller.initialize();

    if (!mounted) return;
    setState(() => _inicializado = true);

    bool terminado = false;
    _controller.addListener(() {
      if (!terminado &&
          _controller.value.position >= _controller.value.duration &&
          !_controller.value.isPlaying) {
        terminado = true;
        if (mounted) {
          setState(() => _mostrandoMensaje = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    });

    await _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_inicializado)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          AnimatedOpacity(
            opacity: _mostrandoMensaje ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: Container(
              color: Colors.black.withOpacity(0.65),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '¡Surge ahora y obedece mi llamada! 🦝✨' ,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
