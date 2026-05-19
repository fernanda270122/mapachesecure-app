import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/auth/reset_password_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mapachesecure_app/screens/hijo/app_bloqueada_screen.dart';
import 'package:mapachesecure_app/services/guardian_service.dart';
import 'package:mapachesecure_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeGuardian();
  await NotificationService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TemaProvider()..cargar(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _escucharDeepLinks();

    FlutterBackgroundService().on('mostrarBloqueo').listen((event) async {
      final auth = AuthService();
      final prefs = await SharedPreferences.getInstance();

      final String? userId = prefs.getString('user_id');
      final String? rol = await auth.getRol();

      // SOLO bloqueamos si el usuario existe y es hijo
      if (userId != null &&
          userId.isNotEmpty &&
          rol == 'hijo' &&
          event != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/pantalla-bloqueo',
          (route) => false,
          arguments: event['app'],
        );
      } else {
        print(
          "🚫 Bloqueo descartado por seguridad (Sesión no válida para hijo)",
        );
      }
    });
  }

  void _escucharDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _procesarLink(uri);
    }
    _appLinks.uriLinkStream.listen((uri) {
      _procesarLink(uri);
    });
  }

  void _procesarLink(Uri uri) {
    if (uri.scheme == 'mapachesecure' && uri.host == 'reset-password') {
      final fragment = uri.fragment;
      final params = Uri.splitQueryString(fragment);
      final token = params['access_token'];
      final type = params['type'];
      if (token != null && type == 'recovery') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(accessToken: token),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Raccu',

      routes: {
        '/home-hijo': (context) => const HomeHijoScreen(),
        '/pantalla-bloqueo': (context) {
          // Esto extrae el nombre que enviamos arriba en 'arguments'
          final String nombre =
              ModalRoute.of(context)?.settings.arguments as String? ?? "App";
          return AppBloqueadaScreen(nombreAppIntentada: nombre);
        },
      },

      theme: ThemeData(
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textDark),
          bodyLarge: TextStyle(color: AppColors.textDark),
          titleMedium: TextStyle(color: AppColors.textDark),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }
  Future<void> _verificarSesion() async {
    final auth = AuthService();
    final service = FlutterBackgroundService();

    await Future.delayed(const Duration(seconds: 3));
    final loggedIn = await auth.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final rol = await auth.getRol();
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      // Migración: usuarios que ya tenían cuenta antes del onboarding
      final migrationDone = prefs.getBool('migration_onboarding_v1') ?? false;
      if (!migrationDone) {
        await prefs.setBool('onboarding_${userId}_${rol}_visto', true);
        await prefs.setBool('migration_onboarding_v1', true);
      }

      final onboardingVisto = prefs.getBool('onboarding_${userId}_${rol}_visto') ?? false;

      if (rol == 'padre') {
        // SEGURIDAD: Si entra el padre, matamos al Guardián inmediatamente
        if (await service.isRunning()) {
          service.invoke("stopService");
        }

        final destino = const HomePadreScreen();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => onboardingVisto
                ? destino
                : OnboardingScreen(rol: 'padre', destino: destino),
          ),
        );
      } else if (rol == 'hijo') {
        // SOLO aquí permitimos que el Guardián viva
        if (!(await service.isRunning())) {
          await service.startService();
        }

        final destino = const HomeHijoScreen();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => onboardingVisto
                ? destino
                : OnboardingScreen(rol: 'hijo', destino: destino),
          ),
        );
      }
    } else {
      // SEGURIDAD: Si no hay nadie logueado (Login Screen), el Guardián DEBE morir
      if (await service.isRunning()) {
        service.invoke("stopService");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.6,
            child: Image.asset(
              'assets/raccu.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          const ColoredBox(color: Color(0x881A237E)),
        ],
      ),
    );
  }
}
