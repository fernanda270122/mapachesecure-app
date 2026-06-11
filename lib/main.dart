import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 📦 1. Importamos la librería de adaptabilidad global
import 'package:http/http.dart' as http;
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/auth/reset_password_screen.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:mapachesecure_app/screens/hijo/home_hijo_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mapachesecure_app/screens/hijo/app_bloqueada_screen.dart';
import 'package:mapachesecure_app/services/guardian_service.dart';
import 'package:mapachesecure_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeGuardian();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemaProvider()..cargar()),
        ChangeNotifierProvider(
          create: (_) => TemaPadreProvider()..cargarTemaPadre(),
        ),
        ChangeNotifierProvider(create: (_) => ActividadProvider()),
      ],
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
    // 📦 2. Envolvemos el árbol con ScreenUtilInit para automatizar todo el sistema visual
    return ScreenUtilInit(
      designSize: const Size(
        375,
        812,
      ), // Medida de lienzo base idónea (ej. iPhone 13/X o emulador estándar)
      minTextAdapt:
          true, // Hace que el motor calcule dinámicamente las densidades del texto
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Raccu',

          routes: {
            '/home-hijo': (context) => const HomeHijoScreen(),
            '/pantalla-bloqueo': (context) {
              final String nombre =
                  ModalRoute.of(context)?.settings.arguments as String? ??
                  "App";
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
                shape: const RoundedRectangleBorder(
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
          home:
              child, // 📦 3. Asigna la propiedad child provista por el builder
        );
      },
      // 📦 4. Declaramos la pantalla raíz aquí afuera para que ScreenUtil inyecte sus dimensiones antes de construirla
      child: const SplashScreen(),
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

      if (rol == 'padre') {
        if (await service.isRunning()) {
          service.invoke("stopService");
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePadreScreen()),
        );
      } else if (rol == 'hijo') {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';
        final onboardingVisto = prefs.getBool('onboarding_${userId}_hijo_visto') ?? false;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => onboardingVisto
                ? const HomeHijoScreen()
                : OnboardingScreen(
                    rol: 'hijo',
                    destino: const HomeHijoScreen(),
                    userId: userId,
                  ),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.asset(
        'assets/raccu.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
