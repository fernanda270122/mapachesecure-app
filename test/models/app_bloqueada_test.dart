import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/app_bloqueada.dart';

void main() {
  group('Pruebas unitarias para el modelo AppBloqueada', () {
    // Datos ficticios que simulan la respuesta exacta del backend (en snake_case)
    final Map<String, dynamic> jsonDePrueba = {
      'id': 'app_123',
      'hijo_id': 'hijo_abc',
      'nombre_app': 'YouTube',
      'package_name': 'com.google.android.youtube',
      'requiere_desafio': true,
      'fecha_creacion': '2026-06-04T12:00:00.000Z',
    };

    test(
      '1. Debería construir una instancia correcta desde un JSON (fromJson)',
      () {
        // Act: Convertimos el JSON al objeto de Dart
        final app = AppBloqueada.fromJson(jsonDePrueba);

        // Assert: Validamos que las propiedades se hayan mapeado y transformado bien
        expect(app.id, 'app_123');
        expect(
          app.hijoId,
          'hijo_abc',
        ); // Verifica que pasó de snake_case a camelCase
        expect(app.nombreApp, 'YouTube');
        expect(app.packageName, 'com.google.android.youtube');
        expect(app.requiereDesafio, true);
        expect(app.fechaCreacion, isA<DateTime>());
        expect(app.fechaCreacion?.year, 2026);
      },
    );

    test('2. Debería manejar valores alternativos o nulos en desde el JSON', () {
      final Map<String, dynamic> jsonConEnteroYNulo = {
        'id': 999, // ID enviado como número entero en vez de String
        'requiere_desafio':
            1, // En el backend a veces los booleanos llegan como 1 o 0
        'fecha_creacion': null,
      };

      final app = AppBloqueada.fromJson(jsonConEnteroYNulo);

      // Assert: Verifica la tolerancia y formateo de fallos del constructor factory
      expect(
        app.id,
        '999',
      ); // Se transformó exitosamente a String con .toString()
      expect(
        app.requiereDesafio,
        true,
      ); // El entero '1' se evaluó correctamente como true
      expect(app.fechaCreacion, null); // Manejó el null sin lanzar excepciones
    });

    test(
      '3. El método toJson debe estructurar los datos correctamente para el servidor',
      () {
        final app = AppBloqueada(
          id: '123',
          hijoId: 'hijo_abc',
          nombreApp: 'TikTok',
          packageName: 'com.zhiliaoapp.musically',
          requiereDesafio: false,
        );

        final resultadoJson = app.toJson();

        // Assert: Asegura que el mapa resultante tenga exactamente las llaves esperadas por la API
        expect(resultadoJson['hijo_id'], 'hijo_abc');
        expect(resultadoJson['nombre_app'], 'TikTok');
        expect(resultadoJson['package_name'], 'com.zhiliaoapp.musically');
        expect(resultadoJson['requiere_desafio'], false);
        expect(
          resultadoJson.containsKey('id'),
          false,
        ); // toJson común no debe llevar ID según tu código
      },
    );

    test('4. El método toJsonUpdate debe incluir el ID del registro', () {
      final app = AppBloqueada(
        id: '123',
        hijoId: 'hijo_abc',
        nombreApp: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        requiereDesafio: false,
      );

      final resultadoJson = app.toJsonUpdate();

      // Assert: Aquí sí verificamos la existencia del ID para las actualizaciones del backend
      expect(resultadoJson['id'], '123');
      expect(resultadoJson['nombre_app'], 'TikTok');
    });

    test(
      '5. El método copyWith debe clonar modificando solo los atributos indicados',
      () {
        final appOriginal = AppBloqueada(
          id: '1',
          hijoId: 'hijo_original',
          nombreApp: 'Roblox',
          packageName: 'com.roblox.client',
        );

        // Clonamos cambiando solo el nombre y el requerimiento de desafío
        final appClonada = appOriginal.copyWith(
          nombreApp: 'Roblox Beta',
          requiereDesafio: false,
        );

        // Assert: Verificar que lo modificado cambió y lo demás se mantuvo intacto
        expect(appClonada.nombreApp, 'Roblox Beta');
        expect(appClonada.requiereDesafio, false);
        expect(appClonada.id, '1'); // Se mantuvo igual
        expect(appClonada.packageName, 'com.roblox.client'); // Se mantuvo igual
      },
    );
  });
}
