import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/auth/reset_password_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
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
      title: 'MapacheSecure',
      theme: ThemeData(       
      iconTheme: const IconThemeData(color: Colors.white),                                                                                                                                                                      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(                                                                                                                                                            seedColor: AppColors.accent,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
    await Future.delayed(const Duration(seconds: 3));
    final loggedIn = await auth.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
      final rol = await auth.getRol();
      if (!mounted) return;
      if (rol == 'padre') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePadreScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

@override                                                                                                                                                                                   Widget build(BuildContext context) {
    return Scaffold(                                                                                                                                                                              body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.6,
            child: Image.asset('assets/raccu.png', 
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