import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';
import 'package:mapachesecure_app/screens/auth/reset_password_screen.dart';
import 'package:mapachesecure_app/screens/padre/home_padre_screen.dart';
import 'package:mapachesecure_app/services/auth_service.dart';

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

  void _escucharDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MapacheSecure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
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
            child: Image.asset('assets/fondo2.jpeg', 
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