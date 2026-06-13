import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/usuario.dart';
import 'package:mapachesecure_app/models/app_bloqueada.dart';
import 'package:mapachesecure_app/models/pet_model.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/hijo/pantalla_bloqueo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── FRENTE 1: Autenticación y control de acceso (OWASP A01 / A07) ──────────

  group('Seguridad - autenticación y control de acceso (A01 / A07)', () {
    // A07: sin token válido, la sesión no está activa
    test('sin token almacenado no hay sesión activa', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AuthService().isLoggedIn(), false);
    });

    // A07: eliminar el token revoca el acceso de inmediato
    test('eliminar el token cierra la sesión aunque la app siga abierta',
        () async {
      SharedPreferences.setMockInitialValues({'token': 'token_valido'});
      final auth = AuthService();
      expect(await auth.isLoggedIn(), true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      expect(await auth.isLoggedIn(), false);
    });

    // A01: un hijo no puede tener permisos de padre
    test('usuario con rol hijo no puede ser reconocido como padre', () {
      final hijo = Usuario.fromJson({
        'id': 'hijo_001',
        'nombre': 'Catalina',
        'email': 'cata@gmail.com',
        'rol': 'hijo',
        'edad': 12,
      });

      expect(hijo.esHijo, true);
      expect(hijo.esPadre, false);
    });

    // A01: la pantalla de bloqueo no puede cerrarse con el botón de retroceso
    testWidgets('PantallaBloqueoScreen no puede ser cerrada por el hijo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PantallaBloqueoScreen(
            horaInicio: '22:00',
            horaFin: '23:59',
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, false);
    });
  });

  // ── FRENTE 2: Validación de datos recibidos del backend (OWASP A05) ────────

  group('Seguridad - validación de datos del servidor (A05)', () {
    // A05: nombre de usuario con script injection se trata como texto plano
    test('nombre de usuario con HTML desde el servidor no se ejecuta', () {
      final usuario = Usuario.fromJson({
        'id': 'usr_001',
        'nombre': "<script>alert('hack')</script>",
        'email': 'test@test.com',
        'rol': 'padre',
      });

      expect(usuario.nombre, "<script>alert('hack')</script>");
      expect(usuario.nombre, isA<String>());
    });

    // A05: package name malicioso de una app bloqueada no rompe el modelo
    test('package name con caracteres especiales se almacena como texto plano',
        () {
      final app = AppBloqueada.fromJson({
        'id': 'app_001',
        'hijo_id': 'hijo_001',
        'nombre_app': 'App Peligrosa',
        'package_name': "'; DROP TABLE apps; --",
        'requiere_desafio': true,
      });

      expect(app.packageName, "'; DROP TABLE apps; --");
      expect(app.packageName, isA<String>());
    });

    // A05: puntos negativos desde el servidor no crashean el PetModel
    test('puntos negativos del servidor no rompen el nivel de la mascota', () {
      const pet = PetModel(puntos: -500);

      expect(pet.nivel, 0);
      expect(pet.imagePath, 'assets/mascota/raccu.png');
    });
  });
}
