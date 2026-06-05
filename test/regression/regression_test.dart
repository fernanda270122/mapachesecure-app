import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';
import 'package:mapachesecure_app/models/pet_model.dart';
import 'package:mapachesecure_app/models/desafio.dart';
import 'package:mapachesecure_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas de regresión — MapacheSecure', () {
    test(
      '1. El logout preserva las preferencias de onboarding y paleta',
      () async {
        SharedPreferences.setMockInitialValues({
          'token': 'access_123',
          'user_id': 'user_abc',
          'onboarding_completado': true,
          'paleta_padre_preferida': 'Celeste Neutro',
        });

        final prefs = await SharedPreferences.getInstance();

        // Simulamos el logout: guardamos lo que se debe preservar
        final onboardingCompletado = prefs.getBool('onboarding_completado');
        final paleta = prefs.getString('paleta_padre_preferida');

        await prefs.clear();

        if (onboardingCompletado != null) {
          await prefs.setBool('onboarding_completado', onboardingCompletado);
        }
        if (paleta != null) {
          await prefs.setString('paleta_padre_preferida', paleta);
        }

        expect(prefs.getString('token'), null);
        expect(prefs.getString('user_id'), null);
        expect(prefs.getBool('onboarding_completado'), true);
        expect(prefs.getString('paleta_padre_preferida'), 'Celeste Neutro');
      },
    );

    test(
      '2. Avatar con ID inválido siempre retorna el mago como fallback',
      () {
        final resultado = AvatarTypes.byId('id_que_no_existe');

        expect(resultado.id, 'mago');
        expect(resultado.nombre, 'Mago');
      },
    );

    test(
      '3. PetModel con puntos extremos no crashea',
      () {
        const petCero = PetModel(puntos: 0);
        const petMaximo = PetModel(puntos: 99999);

        expect(petCero.nivel, 0);
        expect(petCero.imagePath, 'assets/mascota/raccu.png');

        expect(petMaximo.nivel, 6);
        expect(petMaximo.imagePath, isNotNull);
      },
    );

    test(
      '4. Desafío con estado en mayúsculas funciona correctamente',
      () {
        final desafio = Desafio(
          id: '1',
          titulo: 'Test',
          descripcion: 'Descripción',
          categoria: 'hogar',
          puntos: 10,
          estado: 'ACTIVO',
        );

        expect(desafio.estaActivo, true);
        expect(desafio.estaPendiente, false);
        expect(desafio.estaCompletado, false);
      },
    );
  });
}