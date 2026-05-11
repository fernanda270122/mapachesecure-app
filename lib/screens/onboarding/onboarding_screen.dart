import 'package:flutter/material.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final String rol;
  final Widget destino;
  const OnboardingScreen({super.key, required this.rol, required this.destino});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _paginaActual = 0;

  List<Map<String, dynamic>> get _slides =>
      widget.rol == 'padre' ? _slidesPadre : _slidesHijo;

  final _slidesPadre = [
    {
      'icono': Icons.shield,
      'color': Color(0xFF1A237E),
      'titulo': '¡Bienvenido a MapacheSecure!',
      'descripcion': 'Protege el tiempo digital de tus hijos de forma inteligente y positiva.',
    },
    {
      'icono': Icons.person_add,
      'color': Colors.purple,
      'titulo': 'Agrega a tus hijos',
      'descripcion': 'Registra a cada hijo con su nombre y edad para personalizar su experiencia.',
    },
    {
      'icono': Icons.block,
      'color': Colors.red,
      'titulo': 'Configura bloqueos',
      'descripcion': 'Define horarios, fechas o activa bloqueos inmediatos para las apps de tus hijos.',
    },
    {
      'icono': Icons.emoji_events,
      'color': Colors.orange,
      'titulo': 'Asigna desafíos',
      'descripcion': 'Motiva a tus hijos con desafíos cognitivos, físicos y del hogar para ganar puntos.',
    },
    {
      'icono': Icons.star,
      'color': Colors.green,
      'titulo': '¡Todo listo!',
      'descripcion': 'Ya puedes empezar a usar MapacheSecure. ¡Tu familia te lo agradecerá!',
    },
  ];

  final _slidesHijo = [
    {
      'icono': Icons.waving_hand,
      'color': Color(0xFF1A237E),
      'titulo': '¡Hola! Bienvenido a MapacheSecure',
      'descripcion': 'Tu app para organizar tu tiempo con el celular de forma divertida.',
    },
    {
      'icono': Icons.task_alt,
      'color': Colors.purple,
      'titulo': 'Completa desafíos',
      'descripcion': 'Tu papá o mamá te asignará tareas. ¡Completa las y sube una foto como evidencia!',
    },
    {
      'icono': Icons.star,
      'color': Colors.orange,
      'titulo': 'Gana puntos',
      'descripcion': 'Cada desafío completado te da puntos que puedes canjear por recompensas.',
    },
    {
      'icono': Icons.pets,
      'color': Colors.brown,
      'titulo': 'Tu mascota Raccu',
      'descripcion': 'Raccu es tu mapache personal. ¡Hazlo crecer acumulando más puntos!',
    },
    {
      'icono': Icons.rocket_launch,
      'color': Colors.green,
      'titulo': '¡Comencemos!',
      'descripcion': '¡Empieza tu aventura con Raccu y demuestra lo que puedes lograr!',
    },
  ];

  Future<void> _terminar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_${widget.rol}_visto', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esUltima = _paginaActual == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón saltar
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _terminar,
                child: const Text('Saltar', style: TextStyle(color: Colors.grey)),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: (slide['color'] as Color).withOpacity(0.1),
                          child: Icon(
                            slide['icono'] as IconData,
                            size: 70,
                            color: slide['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['titulo'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['descripcion'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicadores de página
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _paginaActual == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _paginaActual == i ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            const SizedBox(height: 30),

            // Botón siguiente / comenzar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (esUltima) {
                      _terminar();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    esUltima ? '¡Comenzar!' : 'Siguiente',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}