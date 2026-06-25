import 'package:flutter_test/flutter_test.dart';
// Asegúrate de cambiar esto por la ruta exacta de tu proyecto
import 'package:mapachesecure_app/models/recompensa.dart';

void main() {
  group('Pruebas unitarias para el modelo Recompensa', () {
    // JSON de prueba simulando la respuesta en snake_case del servidor
    final Map<String, dynamic> jsonCompleto = {
      'id': 'rec_999',
      'titulo': '30 minutos de videojuegos',
      'descripcion':
          'Canjea este premio para desbloquear tiempo en tu consola.',
      'costo_puntos': 300,
      'icono': 'gamepad',
      'disponible': true,
      'padre_id': 'padre_xyz',
      'fecha_creacion': '2026-06-04T15:30:00.000Z',
    };

    test('1. Debería construir una instancia perfecta desde fromJson', () {
      final recompensa = Recompensa.fromJson(jsonCompleto);

      expect(recompensa.id, 'rec_999');
      expect(recompensa.titulo, '30 minutos de videojuegos');
      expect(recompensa.costoPuntos, 300);
      expect(recompensa.icono, 'gamepad');
      expect(recompensa.disponible, true);
      expect(recompensa.padreId, 'padre_xyz');
      expect(recompensa.fechaCreacion, isA<DateTime>());
    });

    test(
      '2. Debe manejar casteo seguro de costos float a enteros y valores nulos',
      () {
        final Map<String, dynamic> jsonConDatosExtranjos = {
          'id': 123, // ID enviado como número entero
          'costo_puntos': 150.7, // El backend envía un float por error
          'icono': null,
          'disponible': null,
        };

        final recompensa = Recompensa.fromJson(jsonConDatosExtranjos);

        expect(recompensa.id, '123'); // Transformado a String
        expect(recompensa.costoPuntos, 150); // Casteado a int con éxito
        expect(recompensa.icono, 'stars'); // Valor por defecto
        expect(recompensa.disponible, true); // Valor por defecto
      },
    );

    test(
      '3. El método toJson debe omitir llaves opcionales si ID está vacío o campos son nulos',
      () {
        final recompensaNueva = Recompensa(
          id: '', // ID vacío porque aún no se guarda en el backend
          titulo: 'Helado el fin de semana',
          descripcion: 'Premio familiar',
          costoPuntos: 100,
          // padreId y fechas se quedan nulos
        );

        final jsonResultante = recompensaNueva.toJson();

        expect(jsonResultante['titulo'], 'Helado el fin de semana');
        expect(jsonResultante['costo_puntos'], 100);
        // Validamos los condicionales inline del mapa toJson
        expect(jsonResultante.containsKey('id'), false);
        expect(jsonResultante.containsKey('padre_id'), false);
        expect(jsonResultante.containsKey('fecha_creacion'), false);
      },
    );

    test(
      '4. El método puedesCanjear debe validar correctamente el balance de puntos del hijo',
      () {
        final premioCaro = Recompensa(
          id: '1',
          titulo: 'A',
          descripcion: 'B',
          costoPuntos: 500,
        );

        // Caso A: El hijo tiene menos puntos de los requeridos
        expect(premioCaro.puedesCanjear(450), false);

        // Caso B: El hijo tiene exactamente los puntos necesarios (frontera)
        expect(premioCaro.puedesCanjear(500), true);

        // Caso C: El hijo tiene puntos de sobra
        expect(premioCaro.puedesCanjear(1000), true);
      },
    );

    test(
      '5. El método copyWith debe generar un nuevo objeto respetando la inmutabilidad',
      () {
        final original = Recompensa(
          id: '1',
          titulo: 'Original',
          descripcion: 'D',
          costoPuntos: 50,
          disponible: true,
        );

        final modificado = original.copyWith(
          disponible: false,
          costoPuntos: 75,
        );

        expect(modificado.id, '1');
        expect(modificado.titulo, 'Original');
        expect(modificado.disponible, false); // Cambió
        expect(modificado.costoPuntos, 75); // Cambió
      },
    );

    test(
      '6. copyWith sin costoPuntos ni disponible usa los valores de la instancia',
      () {
        final original = Recompensa(
          id: '1',
          titulo: 'Premio',
          descripcion: 'D',
          costoPuntos: 200,
          disponible: false,
        );
        // Solo cambia titulo: costoPuntos y disponible quedan null → this.X evaluado
        final clone = original.copyWith(titulo: 'Premio actualizado');
        expect(clone.costoPuntos, 200);
        expect(clone.disponible, false);
      },
    );

    test('7. toString retorna representación con titulo y costo', () {
      final r = Recompensa(
        id: '1',
        titulo: 'Helado',
        descripcion: 'D',
        costoPuntos: 100,
      );
      expect(r.toString(), contains('Helado'));
    });
  });
}
