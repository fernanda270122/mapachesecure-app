import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/pet_model.dart';

void main() {
  group('Pruebas unitarias para el modelo PetModel', () {
    test(
      '1. Debería inicializar con valores por defecto (0 puntos y tipo mago)',
      () {
        const pet = PetModel();

        expect(pet.puntos, 0);
        expect(pet.tipoAvatar, 'mago');
        expect(pet.nivel, 0);
      },
    );

    test(
      '2. El algoritmo de nivel debe calcular el rango correcto según los puntos acumulados',
      () {
        // Tramo 0: Menos de 500 puntos
        expect(const PetModel(puntos: 0).nivel, 0);
        expect(const PetModel(puntos: 499).nivel, 0);

        // Tramo 1: [500 - 1099]
        expect(const PetModel(puntos: 500).nivel, 1);
        expect(const PetModel(puntos: 1099).nivel, 1);

        // Tramo 2: [1100 - 1899]
        expect(const PetModel(puntos: 1100).nivel, 2);
        expect(const PetModel(puntos: 1899).nivel, 2);

        // Tramo 5: [4100 - 5499]
        expect(const PetModel(puntos: 4100).nivel, 5);

        // Tramo 6: 5500 puntos o más
        expect(const PetModel(puntos: 5500).nivel, 6);
        expect(const PetModel(puntos: 10000).nivel, 6); // Límite superior
      },
    );

    test(
      '3. El getter imagePath debe retornar la imagen base del mapache si el nivel es 0',
      () {
        const petNivelCero = PetModel(puntos: 350, tipoAvatar: 'ninja');

        // Si tiene nivel 0, ignora el tipoAvatar y va al asset genérico raccu.png
        expect(petNivelCero.imagePath, 'assets/mascota/raccu.png');
      },
    );

    test(
      '4. El getter imagePath debe resolver la ruta de asset específica según el avatar y el nivel superior',
      () {
        // 1100 puntos equivale exactamente a Nivel 2. Tipo: ninja
        const petNivelDos = PetModel(puntos: 1100, tipoAvatar: 'ninja');

        // Debería invocar internamente a AvatarTypes y resolver la imagen del nivel 2 del ninja
        expect(petNivelDos.imagePath, 'assets/mascota/ninja2.jpeg');
      },
    );

    test(
      '5. El getter imagePath debe usar fallback del Mago si se ingresa un avatar inválido',
      () {
        // 500 puntos equivale a Nivel 1. Tipo: inexistente o corrupto
        const petInvalido = PetModel(
          puntos: 500,
          tipoAvatar: 'dragon_fantasma',
        );

        // Al no existir, AvatarTypes.byId lo maneja retornando el 'mago' en nivel 1
        expect(petInvalido.imagePath, 'assets/mascota/magonivel1.png');
      },
    );
  });
}
