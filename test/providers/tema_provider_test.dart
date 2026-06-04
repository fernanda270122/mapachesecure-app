import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas unitarias para TemaProvider', () {
    test('1. El valor inicial por defecto debe ser Lavanda', () {
      // Configura un entorno limpio para SharedPreferences vacío
      SharedPreferences.setMockInitialValues({});

      final temaProvider = TemaProvider();

      // Al instanciarlo, el valor privado _paleta arranca en 'Lavanda'
      expect(temaProvider.paleta, 'Lavanda');
    });

    test(
      '2. Debe cargar la paleta guardada previamente desde SharedPreferences',
      () async {
        // Simulamos que el dispositivo ya tenía guardado 'Menta'
        SharedPreferences.setMockInitialValues({'paleta_hijo': 'Menta'});

        final temaProvider = TemaProvider();

        // Ejecutamos el método cargar
        await temaProvider.cargar();

        // Verificamos que leyera el mock correctamente y notificara el cambio
        expect(temaProvider.paleta, 'Menta');
      },
    );

    test(
      '3. El método cambiar debe actualizar la paleta y persistir el dato',
      () async {
        // Arrancamos con SharedPreferences vacío
        SharedPreferences.setMockInitialValues({});

        final temaProvider = TemaProvider();

        // Ejecutamos el cambio a una nueva paleta (por ejemplo, 'Azul' o la que tengas en tu paleta)
        await temaProvider.cambiar('Océano');

        // Verificación 1: El estado en memoria cambió
        expect(temaProvider.paleta, 'Océano');

        // Verificación 2: El dato se guardó físicamente en las preferencias compartidas
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('paleta_hijo'), 'Océano');
      },
    );
  });
}
