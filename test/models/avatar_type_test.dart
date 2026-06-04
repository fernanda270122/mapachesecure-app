import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/avatar_type.dart';

void main() {
  group('Pruebas unitarias para AvatarType y AvatarTypes', () {
    test(
      '1. El getter preview debe devolver la imagen del primer nivel (índice 0)',
      () {
        final avatar = AvatarTypes.mago;

        // El primer elemento de la lista del mago es 'assets/mascota/magonivel1.png'
        expect(avatar.preview, 'assets/mascota/magonivel1.png');
      },
    );

    test(
      '2. El método imagenNivel debe calcular el índice correcto para niveles válidos',
      () {
        final avatar = AvatarTypes.ninja;

        // Nivel 1 -> Índice 0
        expect(avatar.imagenNivel(1), 'assets/mascota/ninja1.jpeg');
        // Nivel 4 -> Índice 3
        expect(avatar.imagenNivel(4), 'assets/mascota/ninja4.jpeg');
        // Nivel 6 -> Índice 5
        expect(avatar.imagenNivel(6), 'assets/mascota/ninja6.jpeg');
      },
    );

    test(
      '3. El método imagenNivel debe acotar (clamp) los niveles fuera de rango para evitar desbordamientos',
      () {
        final avatar = AvatarTypes.gamer;

        // Si el backend o la lógica del niño envía nivel 0, clamp debe forzarlo a nivel 1 (índice 0)
        expect(avatar.imagenNivel(0), 'assets/mascota/gamer1.png');

        // Si envía nivel 99, clamp debe acotarlo al nivel máximo 6 (índice 5)
        expect(avatar.imagenNivel(99), 'assets/mascota/gamer6.jpeg');
      },
    );

    test(
      '4. AvatarTypes.byId debe encontrar el avatar correcto por su ID único',
      () {
        // Buscamos un ID existente
        final resultado = AvatarTypes.byId('samuray');

        expect(resultado.nombre, 'Samurái');
        expect(resultado.id, 'samuray');
      },
    );

    test(
      '5. AvatarTypes.byId debe devolver al Mago por defecto si el ID no existe',
      () {
        // Pasamos un ID inventado o corrupto
        final resultado = AvatarTypes.byId('avatar_fantasma_999');

        // Según tu código 'orElse: () => mago', debe mitigar el fallo retornando el mago fijo
        expect(resultado.id, 'mago');
        expect(resultado.nombre, 'Mago');
      },
    );

    test(
      '6. La lista completa de avatares debe contener los 6 tipos definidos',
      () {
        // Asegurar que ningún avatar se haya quedado fuera de la lista global
        expect(AvatarTypes.todos.length, 6);

        final ids = AvatarTypes.todos.map((a) => a.id).toList();
        expect(
          ids,
          containsAll([
            'mago',
            'dormilon',
            'gamer',
            'ninja',
            'samuray',
            'princes',
          ]),
        );
      },
    );
  });
}
