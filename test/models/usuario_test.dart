import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/usuario.dart';

void main() {
  group('Pruebas unitarias para el modelo Usuario', () {
    // JSON de prueba emulando la respuesta típica del backend para un perfil Hijo
    final Map<String, dynamic> jsonHijoCompleto = {
      'id': 'user_001',
      'nombre': 'Pedrito',
      'email': 'pedrito@mapache.com',
      'rol': 'hijo',
      'edad': 10,
      'tiempo_limite_minutos': 90,
    };

    test(
      '1. Debería construir una instancia correcta desde fromJson (Perfil Hijo)',
      () {
        final usuario = Usuario.fromJson(jsonHijoCompleto);

        expect(usuario.id, 'user_001');
        expect(usuario.nombre, 'Pedrito');
        expect(usuario.email, 'pedrito@mapache.com');
        expect(usuario.rol, 'hijo');
        expect(usuario.edad, 10);
        expect(usuario.tiempoLimiteMinutos, 90);
        expect(usuario.esHijo, true);
        expect(usuario.esPadre, false);
      },
    );

    test(
      '2. Debería manejar de forma segura los valores nulos y por defecto (Perfil Padre)',
      () {
        final Map<String, dynamic> jsonPadre = {
          'id': 'user_002',
          'nombre': 'Carlos',
          'email': 'carlos@mapache.com',
          'rol': 'padre',
          'edad': null, // Los padres no registran edad
          'tiempo_limite_minutos':
              null, // Los padres no tienen límite de pantalla
        };

        final usuario = Usuario.fromJson(jsonPadre);

        expect(usuario.id, 'user_002');
        expect(usuario.rol, 'padre');
        expect(usuario.edad, null); // Maneja el nulo sin caerse
        expect(
          usuario.tiempoLimiteMinutos,
          120,
        ); // Aplica el fallback de 120 minutos por defecto
        expect(usuario.esPadre, true);
        expect(usuario.esHijo, false);
      },
    );

    test(
      '3. Debe mitigar fallos de tipo convirtiendo floats a enteros en la edad y límites',
      () {
        final Map<String, dynamic> jsonTiposCorruptos = {
          'id': 777, // ID enviado como int en lugar de String
          'nombre': 'Javier',
          'email': 'javier@mapache.com',
          'edad': 12.5, // El backend manda un float por error
          'tiempo_limite_minutos': 60.0,
        };

        final usuario = Usuario.fromJson(jsonTiposCorruptos);

        expect(usuario.id, '777');
        expect(usuario.edad, 12); // Convertido a int de forma limpia
        expect(
          usuario.tiempoLimiteMinutos,
          60,
        ); // Convertido a int de forma limpia
      },
    );

    test(
      '4. El método toJson debe estructurar adecuadamente las propiedades omitiendo campos nulos',
      () {
        final usuarioPadre = Usuario(
          id: '123',
          nombre: 'Isabel',
          email: 'isabel@mapache.com',
          rol: 'padre',
          edad: null, // Sin edad
          tiempoLimiteMinutos: 0,
        );

        final jsonResultante = usuarioPadre.toJson();

        expect(jsonResultante['nombre'], 'Isabel');
        expect(jsonResultante['rol'], 'padre');
        // Verificamos los condicionales inline del mapa toJson
        expect(jsonResultante.containsKey('edad'), false);
      },
    );

    test(
      '5. El método copyWith debe clonar propiedades manteniendo la inmutabilidad',
      () {
        final original = Usuario(
          id: '1',
          nombre: 'Michu',
          email: 'michu@mapache.com',
          rol: 'hijo',
          edad: 8,
        );

        final clon = original.copyWith(
          nombre: 'Michu Modificado',
          tiempoLimiteMinutos: 180,
        );

        expect(clon.id, '1'); // Atributo heredado idéntico
        expect(clon.edad, 8); // Atributo heredado idéntico
        expect(clon.nombre, 'Michu Modificado'); // Modificado exitosamente
        expect(clon.tiempoLimiteMinutos, 180); // Modificado exitosamente
      },
    );

    test('6. copyWith sin nombre ni tiempoLimiteMinutos usa los valores de la instancia', () {
      final original = Usuario(
        id: '1',
        nombre: 'Pedro',
        email: 'pedro@test.com',
        rol: 'hijo',
        tiempoLimiteMinutos: 90,
      );
      // Solo cambia email: nombre y tiempoLimiteMinutos quedan null → this.X evaluado
      final clone = original.copyWith(email: 'nuevo@test.com');
      expect(clone.nombre, 'Pedro');
      expect(clone.tiempoLimiteMinutos, 90);
    });

    test('7. toString retorna representación con nombre y rol', () {
      final u = Usuario(id: '1', nombre: 'Ana', email: 'ana@test.com', rol: 'padre');
      expect(u.toString(), contains('Ana'));
    });
  });
}
