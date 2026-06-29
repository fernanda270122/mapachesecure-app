import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/screens/hijo/detalle_desafio_screen.dart';
import 'package:mapachesecure_app/screens/hijo/tienda_recompensa_hijo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/services/api_service.dart';
import 'package:mapachesecure_app/screens/hijo/mi_actividad_screen.dart';
import 'package:mapachesecure_app/screens/hijo/mis_desafios_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/hijo/guia_hijo_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mapachesecure_app/models/pet_model.dart';
import 'package:mapachesecure_app/screens/hijo/video_evolucion_screen.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/colores_screen.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
import 'package:mapachesecure_app/screens/hijo/seleccion_avatar_screen.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapachesecure_app/services/notification_service.dart';

class HomeHijoScreen extends StatefulWidget {
  const HomeHijoScreen({super.key});

  @override
  State<HomeHijoScreen> createState() => _HomeHijoScreenState();
}

class _HomeHijoScreenState extends State<HomeHijoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FlutterTts _tts = FlutterTts();
  String _nombre = '';
  String? _avatarPath;
  int _puntos = 0;
  String _tipoAvatar = 'mago';
  List<dynamic> _desafios = [];
  bool _cargando = true;
  bool _refreshando = false;
  bool _navegandoAvatar = false;
  Set<String> _pendientes = {};
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _nivelMascotaVisto = -1;
  bool _enEvolucion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatos();
    try {
      NotificationService().registrarToken().catchError((_) {});
    } catch (_) {}
    _tts.setLanguage('es-MX').catchError((_) {});

    // Llamamos a la validación secuencial inteligente
    _activarGuardian().catchError((_) {});

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true); //
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _cargarNivelVisto();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        "🦝 MapacheSecure: El usuario regresó a la app. Evaluando siguiente permiso...",
      );
      _activarGuardian();
      _cargarDatos(); // Actualiza puntos para detectar evolución pendiente
    }
  }

  Future<void> _cargarNivelVisto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () => _nivelMascotaVisto = prefs.getInt('nivel_mascota_visto') ?? -1,
    );
  }

  Future<void> _verificarEvolucion(int puntos) async {
    if (_enEvolucion) return;
    final nivel = _calcularNivel(puntos)['nivel'] as int;
    debugPrint('🔍 _verificarEvolucion: puntos=$puntos nivel=$nivel nivelVisto=$_nivelMascotaVisto');
    if (nivel < 1 || nivel <= _nivelMascotaVisto) {
      debugPrint('🔍 _verificarEvolucion: skip (nivel<1 o ya visto)');
      return;
    }
    _enEvolucion = true;

    final prefs = await SharedPreferences.getInstance();
    final hijoId = prefs.getString('user_id') ?? '';

    // Primera vez en nivel 1: selección de avatar
    if (_nivelMascotaVisto < 1) {
      final tipoGuardado = prefs.getString('tipo_avatar') ?? '';
      debugPrint('🔍 _verificarEvolucion: tipoGuardado="$tipoGuardado"');
      if (tipoGuardado.isEmpty) {
        if (!mounted) return;
        final elegido = await Navigator.push<String>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const SeleccionAvatarScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        if (elegido != null) {
          await prefs.setString('tipo_avatar', elegido);
          setState(() => _tipoAvatar = elegido);
          try {
            final api = ApiService();
            await api.put('/usuarios/$hijoId/tipo-avatar', {
              'tipo_avatar': elegido,
            });
          } catch (_) {}
        } else {
          // El niño cerró la pantalla sin elegir — no avanzamos nivel
          _enEvolucion = false;
          return;
        }
      } else {
        // Ya tiene avatar guardado, lo carga
        setState(() => _tipoAvatar = tipoGuardado);
      }
    }

    // Reproduce video: "ha despertado" en nivel 1, "subió al nivel N" en 2-6
    final avatar = AvatarTypes.byId(_tipoAvatar);
    final mensaje = nivel == 1
        ? '¡${avatar.nombre} ha despertado! 🦝✨'
        : '¡${avatar.nombre} subió al nivel $nivel! 🦝✨';

    if (avatar.videoPath != null && mounted) {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => VideoEvolucionScreen(
            videoPath: avatar.videoPath!,
            mensaje: mensaje,
          ),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }

    await prefs.setInt('nivel_mascota_visto', nivel);
    setState(() => _nivelMascotaVisto = nivel);
    _enEvolucion = false;
  }

  // Variable para que el cartel explicativo aparezca SOLO la primera vez que se monta la pantalla
  bool _mostrarCartelInicial = true;

  Future<void> _activarGuardian() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (isRunning) return;

    bool usageGranted = await UsageStats.checkUsagePermission() ?? false;
    bool overlayGranted = await Permission.systemAlertWindow.isGranted;

    // 1. Mostrar cartel explicativo SÓLO si falta algún permiso Y es la primera vez que entra
    if ((!usageGranted || !overlayGranted) && _mostrarCartelInicial) {
      _mostrarCartelInicial = false; // Nos aseguramos de apagarlo de inmediato
      if (!mounted) return;

      bool? iniciarFlujo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  "Configuración Requerida",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              "A continuación, MapacheSecure te solicitará 2 permisos del sistema para que el guardián pueda proteger el dispositivo. Por favor, actívalos en cada pantalla que aparezca.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  "ENTENDIDO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (iniciarFlujo != true) return;
    }

    // ==========================================
    // 🚀 FLUJO SECUENCIAL INTERACTIVO (REBOBINADO)
    // ==========================================

    // 🛡️ PASO 1: Acceso a estadísticas de uso
    if (!usageGranted) {
      await UsageStats.grantUsagePermission();
      return; // Manda a Ajustes. Al volver, el observer ejecuta el Paso 2
    }

    // 🛡️ PASO 2: Mostrar sobre otras apps
    if (!overlayGranted) {
      await Permission.systemAlertWindow.request();
      return; // Manda a Ajustes. Al volver, el observer entrará directo al inicio del servicio
    }

    // 🏁 ¡CONTRATO CUMPLIDO! Si llegó aquí es porque tiene los 2 permisos activos.
    if (!isRunning) {
      debugPrint("🚀 Levantando Guardián Raccu de inmediato...");
      await service.startService();
    }
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Explorador';
    final hijoId = prefs.getString('user_id') ?? '';
    final avatar = prefs.getString('avatar_hijo');
    final tipoAvatar = prefs.getString('tipo_avatar') ?? 'mago';

    try {
      final api = ApiService();
      final puntosData = await api.get('/desafios/puntos/$hijoId');
      final desafiosData = await api.get('/desafios/hijo/$hijoId');
      final completadosData = await api.get('/desafios/completados/$hijoId');
      final perfilData = await api.get('/usuarios/$hijoId');
      final nuevoPuntos = puntosData is Map
          ? (puntosData['total_puntos'] ?? 0)
          : 0;

      // tipo_avatar y foto_perfil del backend son fuente de verdad
      String tipoAvatarFinal = tipoAvatar;
      String? avatarFinal = avatar;
      bool tieneAvatarEnBackend = false;
      if (perfilData is Map) {
        if (perfilData['tipo_avatar'] != null) {
          tipoAvatarFinal = perfilData['tipo_avatar'] as String;
          tieneAvatarEnBackend = true;
          if (tipoAvatarFinal != tipoAvatar) {
            await prefs.setString('tipo_avatar', tipoAvatarFinal);
          }
        }
        if (perfilData['foto_perfil'] != null) {
          avatarFinal = perfilData['foto_perfil'] as String;
          if (avatarFinal != avatar) {
            await prefs.setString('avatar_hijo', avatarFinal);
          }
        }
      }

      setState(() {
        if (completadosData is List) {
          _pendientes = completadosData
              .where((c) => c['validado'] == false)
              .map<String>((c) => c['desafio_id'].toString())
              .toSet();
          debugPrint('pendientes: $_pendientes');
        }
        _nombre = nombre;
        _avatarPath = avatarFinal;
        _puntos = nuevoPuntos;
        _tipoAvatar = tipoAvatarFinal;

        if (desafiosData is List) {
          // --- PASO 1: FILTRAR POR ESTADO ACTIVO
          // Primero nos quedamos solo con lo que el padre aprobó
          var listaFiltrada = desafiosData
              .where((d) => d['esta_activo'] == true)
              .toList();

          // --- PASO 2: FILTRAR REPETIDOS ---
          // Sobre la lista ya aprobada, quitamos duplicados por título
          final nombresVistos = <String>{};
          var listaLimpia = listaFiltrada
              .where((d) => nombresVistos.add(d['titulo'] ?? ''))
              .toList();

          var pendientesList = listaLimpia
              .where((d) => _pendientes.contains(d['id'].toString()))
              .toList();
          var disponibles = listaLimpia
              .where((d) => !_pendientes.contains(d['id'].toString()))
              .toList();
          disponibles.shuffle();
          _desafios = [...pendientesList, ...disponibles].take(3).toList();
        } else {
          _desafios = [];
        }
        _cargando = false;
      });

      // Si ya tiene avatar confirmado en el backend, sincroniza nivel_mascota_visto para que
      // al volver a iniciar sesión no se muestre la selección ni videos ya vistos.
      // IMPORTANTE: usar tieneAvatarEnBackend (no tipoAvatarFinal) porque el default
      // local 'mago' haría que esto corriera antes de que el niño haya elegido avatar.
      if (tieneAvatarEnBackend) {
        final nivelActual = _calcularNivel(nuevoPuntos)['nivel'] as int;
        final nivelVisto = prefs.getInt('nivel_mascota_visto') ?? -1;
        if (nivelVisto < nivelActual) {
          await prefs.setInt('nivel_mascota_visto', nivelActual);
          setState(() => _nivelMascotaVisto = nivelActual);
        }
      }

      await _verificarEvolucion(nuevoPuntos);
    } on ApiUnauthorizedException {
      if (_refreshando) {
        await _cerrarSesionPorExpiracion();
        return;
      }
      _refreshando = true;
      final auth = AuthService();
      final renovado = await auth.refreshToken();
      _refreshando = false;
      if (renovado) {
        _cargarDatos();
      } else {
        await _cerrarSesionPorExpiracion();
      }
    } catch (e) {
      debugPrint("Error en Home: $e");
      if (mounted) {
        setState(() {
          _nombre = nombre;
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cerrarSesionPorExpiracion() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) service.invoke("stopService");
    final auth = AuthService();
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión expiró. Inicia sesión nuevamente.'),
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // 🛡️ ESCUDO DE SEGURIDAD PARA CIERRE DE SESIÓN
  void _intentarCerrarSesion(BuildContext context) {
    final tema = context.read<TemaProvider>().colores;
    final emailController = TextEditingController();
    final passController = TextEditingController();
    bool validando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: tema.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: tema.accent),
              const SizedBox(width: 10),
              Text(
                "Validación de Adulto",
                style: TextStyle(color: tema.onBackground, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Para cerrar sesión y desactivar el Guardián, un adulto debe ingresar sus datos.",
                  style: TextStyle(
                    color: tema.onBackground.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  style: TextStyle(color: tema.onBackground),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo del Adulto",
                    labelStyle: TextStyle(color: tema.accent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: tema.onBackground.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tema.accent),
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: tema.onBackground.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passController,
                  obscureText: true,
                  style: TextStyle(color: tema.onBackground),
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: TextStyle(color: tema.accent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: tema.onBackground.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tema.accent),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: tema.onBackground.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "CANCELAR",
                style: TextStyle(
                  color: tema.onBackground.withValues(alpha: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tema.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: validando
                  ? null
                  : () async {
                      setState(() => validando = true);
                      try {
                        final authService = AuthService();
                        final respuesta = await authService.login(
                          emailController.text.trim(),
                          passController.text,
                        );
                        if (respuesta['perfil']['rol'] == 'padre') {
                          // 🛡️ PASO 1: ORDENAR AL GUARDIÁN QUE SE DETENGA
                          final service = FlutterBackgroundService();
                          service.invoke("stopService");

                          // 🛡️ PASO 2: LIMPIAR DATOS
                          final prefs = await SharedPreferences.getInstance();
                          final onboardingKeys = prefs
                              .getKeys()
                              .where((k) => k.startsWith('onboarding_'))
                              .toList();
                          final savedFlags = {
                            for (var k in onboardingKeys) k: prefs.getBool(k),
                          };
                          await prefs.clear();
                          for (final entry in savedFlags.entries) {
                            if (entry.value != null) {
                              await prefs.setBool(entry.key, entry.value!);
                            }
                          }

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } else {
                          throw Exception("No autorizado");
                        }
                      } catch (e) {
                        setState(() => validando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Datos incorrectos o acceso denegado.",
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: validando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("DESACTIVAR Y SALIR"),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calcularNivel(int puntos) {
    const List<int> puntosNivel = [0, 500, 1100, 1900, 2900, 4100, 5500];
    int nivel = 0;
    for (int i = 1; i < puntosNivel.length; i++) {
      if (puntos >= puntosNivel[i]) {
        nivel = i;
      } else {
        break;
      }
    }
    int puntosActual = puntosNivel[nivel];
    int puntosNext = nivel < 6 ? puntosNivel[nivel + 1] : 5500;
    double progreso = nivel < 6
        ? (puntos - puntosActual) / (puntosNext - puntosActual)
        : 1.0;
    return {
      'nivel': nivel,
      'progreso': progreso.clamp(0.0, 1.0),
      'puntosNext': puntosNext,
    };
  }

  IconData _getIcono(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'cognitivo':
        return Icons.psychology;
      case 'fisico':
        return Icons.directions_run;
      case 'orden':
        return Icons.auto_awesome;
      default:
        return Icons.rocket_launch;
    }
  }

  Color _getColor(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'cognitivo':
        return Colors.blue;
      case 'fisico':
        return Colors.orange;
      case 'orden':
        return Colors.teal;
      default:
        return Colors.blueAccent;
    }
  }

  Color _getDificultadColor(String? dificultad) {
    switch (dificultad?.toLowerCase()) {
      case 'facil':
      case 'fácil':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'dificil':
      case 'difícil':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tema.accent, tema.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _avatarPath != null
                        ? AssetImage(_avatarPath!)
                        : null,
                    child: _avatarPath == null
                        ? const Icon(Icons.star, color: Colors.orange, size: 35)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Hola, $_nombre!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Nivel ${_calcularNivel(_puntos)['nivel']}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerOption(
              Icons.emoji_events,
              'Tienda de recompensas',
              Colors.purple,
              () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TiendaRecompensasHijoScreen(),
                  ),
                );
              },
            ),
            _buildDrawerOption(
              Icons.rocket_launch,
              'Mis desafíos',
              Colors.orange,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisDesafiosScreen(),
                  ),
                );
              },
            ),
            _buildDrawerOption(Icons.history, 'Mi Actividad', Colors.white, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MiActividadScreen(),
                ),
              );
            }),
            _buildDrawerOption(
              Icons.help_outline,
              'Guía de la app',
              Colors.purple,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuiaHijoScreen()),
                );
              },
            ),
            _buildDrawerOption(
              Icons.palette_outlined,
              'Colores',
              Colors.teal,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ColoresScreen()),
                );
              },
            ),
            _buildDrawerOption(
              Icons.account_circle,
              'Mi Avatar',
              Colors.deepPurple,
              () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AvatarScreen()),
                );
                if (result != null) setState(() => _avatarPath = result);
              },
            ),
            const Divider(),
            _buildDrawerOption(
              Icons.exit_to_app,
              'Cerrar Sesión',
              Colors.red,
              () {
                // llamamos al escudo
                _intentarCerrarSesion(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh:
                  _cargarDatos, // Implementa refresco manual como en el Padre
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, ${_nombre.split(' ').first}!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: tema.onBackground,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  'Nivel ${_calcularNivel(_puntos)['nivel']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (_navegandoAvatar) return;
                              _navegandoAvatar = true;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AvatarScreen(),
                                ),
                              );
                              _navegandoAvatar = false;
                              if (result != null) {
                                setState(() => _avatarPath = result);
                              }
                            },
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: tema.accent,
                              backgroundImage: _avatarPath != null
                                  ? AssetImage(_avatarPath!)
                                  : null,
                              child: _avatarPath == null
                                  ? const Icon(
                                      Icons.face,
                                      size: 40,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildMascotaCard(),
                      const SizedBox(height: 20),
                      Text(
                        'Desafíos disponibles:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: tema.onBackground,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Generación dinámica de desafíos desde el Backend
                      _desafios.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  "No hay desafíos disponibles",
                                  style: TextStyle(
                                    color: tema.onBackground.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _desafios.map((desafio) {
                                return _buildChallengeCard(
                                  context, // Agregamos el context para navegar
                                  desafio, // Pasamos el mapa completo
                                  _pendientes.contains(
                                    desafio['id'].toString(),
                                  ),
                                );
                              }).toList(),
                            ),

                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TiendaRecompensasHijoScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Recompensas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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

  Widget _buildDrawerOption(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMascotaCard() {
    final nivelInfo = _calcularNivel(_puntos);
    final int nivel = nivelInfo['nivel'];
    final double progreso = nivelInfo['progreso'];
    final int puntosNext = nivelInfo['puntosNext'];
    final pet = PetModel(puntos: _puntos, tipoAvatar: _tipoAvatar);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Image.asset(
                pet.imagePath,
                key: ValueKey(pet.imagePath),
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RaccuPoints',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$_puntos pts',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nivel $nivel — faltan ${puntosNext - _puntos} pts para el siguiente',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 15,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progreso * 100).toInt()}%',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Map<String, dynamic> desafio,
    bool esPendiente,
  ) {
    final String titulo = desafio['titulo'] ?? 'Desafío';
    final String descripcion = desafio['descripcion'] ?? 'Sin descripción';
    final String puntos = '+${desafio['puntos']} pts';
    final String dificultad =
        desafio['dificultad'] ?? 'fácil'; // Valor por defecto

    // Normalizamos el tipo
    String tipoRaw = (desafio['tipo'] ?? 'general').toString().toLowerCase();
    if (tipoRaw == 'cognitivo') tipoRaw = 'cognitiva';
    if (tipoRaw == 'fisico') tipoRaw = 'fisica';

    final IconData icono = _getIcono(tipoRaw);
    final Color color = _getColor(tipoRaw);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior:
          Clip.antiAlias, // Mantiene el badge dentro del radio del Card
      child: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icono, color: color),
              ),
              title: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                ), // Bajamos un poco el título por el badge
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              subtitle: Text(
                tipoRaw.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  puntos,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              descripcion,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.indigo,
                            ),
                            onPressed: () => _tts.speak(descripcion),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: esPendiente
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_top),
                                label: const Text('Pendiente de revisión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade200,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleDesafioScreen(
                                            desafio: desafio,
                                          ),
                                    ),
                                  );
                                  if (resultado == true) _cargarDatos();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  '¡Ir a realizar el desafío!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ETIQUETA DE DIFICULTAD (BADGE)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getDificultadColor(dificultad),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                dificultad.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
