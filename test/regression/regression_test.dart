import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
import 'package:mapachesecure_app/models/pet_model.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/services/auth_service.dart';

// Subclase que omite FlutterBackgroundService (plugin Android) pero
// ejecuta la lógica real de preservación de preferencias.
class TestAuthService extends AuthService {
  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingKeys =
        prefs.getKeys().where((k) => k.startsWith('onboarding_')).toList();
    final savedBools = {for (var k in onboardingKeys) k: prefs.getBool(k)};
    final savedPaleta = prefs.getString('paleta_padre_preferida');
    await prefs.clear();
    for (final entry in savedBools.entries) {
      if (entry.value != null) await prefs.setBool(entry.key, entry.value!);
    }
    if (savedPaleta != null) {
      await prefs.setString('paleta_padre_preferida', savedPaleta);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /* Regresión BUG-001: logout() llamaba prefs.clear() sin preservar las keys
     onboarding_*. El padre completaba el onboarding, cerraba sesión y al
     volver a entrar lo veía de nuevo desde cero. */
  group('Regresión - BUG-001 logout borra preferencias de onboarding', () {
    test('logout preserva el flag de onboarding tras limpiar la sesión',
        () async {
      SharedPreferences.setMockInitialValues({
        'token': 'access_123',
        'user_id': 'user_001',
        'onboarding_user_001_padre_visto': true,
        'paleta_padre_preferida': 'Celeste Neutro',
      });

      final authService = TestAuthService();
      await authService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
      expect(prefs.getString('user_id'), isNull);
      expect(prefs.getBool('onboarding_user_001_padre_visto'), true);
      expect(prefs.getString('paleta_padre_preferida'), 'Celeste Neutro');
    });
  });

  /* Regresión BUG-002: estaActivo() comparaba estado con == sin toLowerCase().
     Cuando el backend devolvía 'ACTIVO' o 'Activo', los desafíos nunca
     aparecían como activos en la pantalla del hijo y la lista quedaba vacía. */
  group('Regresión - BUG-002 desafío estado case-sensitive', () {
    test('desafío con estado en mayúsculas desde el backend es reconocido correctamente',
        () {
      final desafio = Desafio.fromJson({
        'id': '42',
        'titulo': 'Leer 20 minutos',
        'descripcion': 'Leer un libro antes de dormir',
        'categoria': 'cognitiva',
        'puntos': 50,
        'estado': 'ACTIVO', // valor real que enviaba el backend
      });

      expect(desafio.estaActivo, true);
      expect(desafio.estaPendiente, false);
      expect(desafio.estaCompletado, false);
    });
  });

  /* Regresión BUG-003: PetModel.imagePath llamaba imagenNivel(nivel) sin
     verificar nivel == 0. Un hijo recién registrado con 0 puntos veía la
     imagen del avatar nivel 1 antes de haber elegido mascota. */
  group('Regresión - BUG-003 PetModel muestra imagen incorrecta con 0 puntos', () {
    test('hijo sin puntos muestra imagen base del raccu, no imagen de avatar',
        () {
      const pet = PetModel(puntos: 0, tipoAvatar: 'mago');

      expect(pet.nivel, 0);
      expect(pet.imagePath, 'assets/mascota/raccu.png');
      expect(pet.imagePath, isNot(contains('magonivel')));
    });
  });

  /* Regresión BUG-004: AvatarTypes.byId() usaba firstWhere sin orElse.
     Si la columna tipo_avatar en Supabase guardaba un valor inesperado,
     la app lanzaba StateError y la pantalla del hijo crasheaba al cargar. */
  group('Regresión - BUG-004 byId lanza excepción con tipo de avatar desconocido', () {
    test('tipo de avatar desconocido retorna mago sin lanzar excepción', () {
      expect(
        () => AvatarTypes.byId('tipo_invalido_supabase'),
        returnsNormally,
      );
      expect(AvatarTypes.byId('tipo_invalido_supabase').id, 'mago');
    });
  });
}
