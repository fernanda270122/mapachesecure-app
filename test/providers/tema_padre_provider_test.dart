import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';

void main() {
  // Inicializa el entorno para los mocks de Flutter en pruebas unitarias
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas unitarias para TemaPadreProvider', () {
    test('1. El valor inicial por defecto debe ser Celeste Neutro', () {
      // Limpiamos el almacenamiento simulado
      SharedPreferences.setMockInitialValues({});

      final temaPadreProvider = TemaPadreProvider();

      // Verificamos el estado inicial antes de cargar cualquier persistencia
      expect(temaPadreProvider.paletaPadre, 'Celeste Neutro');
    });

    test(
      '2. Debe cargar la paleta del padre guardada previamente desde SharedPreferences',
      () async {
        // Simulamos que el padre ya había elegido la paleta 'Gris Oscuro' (o la que uses)
        SharedPreferences.setMockInitialValues({
          'paleta_padre_preferida': 'Gris Oscuro',
        });

        final temaPadreProvider = TemaPadreProvider();

        // Ejecutamos el método asíncrono de carga
        await temaPadreProvider.cargarTemaPadre();

        // Verificamos que se actualizara correctamente con el valor del mock
        expect(temaPadreProvider.paletaPadre, 'Gris Oscuro');
      },
    );

    test(
      '3. El método cambiarTemaPadre debe actualizar el estado y guardarlo en disco',
      () async {
        // Inicializamos vacío
        SharedPreferences.setMockInitialValues({});

        final temaPadreProvider = TemaPadreProvider();

        // Cambiamos a una nueva paleta de prueba
        await temaPadreProvider.cambiarTemaPadre('Esmeralda');

        // Verificación 1: El estado en memoria cambió inmediatamente
        expect(temaPadreProvider.paletaPadre, 'Esmeralda');

        // Verificación 2: Se persistió en SharedPreferences con la clave correcta
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('paleta_padre_preferida'), 'Esmeralda');
      },
    );
  });
}
