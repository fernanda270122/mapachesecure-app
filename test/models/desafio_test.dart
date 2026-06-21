import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/models/desafio.dart';

void main() {
  group('Pruebas unitarias para el modelo Desafio', () {
    // JSON de prueba simulando la respuesta completa del servidor
    final Map<String, dynamic> jsonCompleto = {
      'id': 'desafio_001',
      'titulo': 'Resolver 5 problemas de matemática',
      'descripcion': 'Completa la sección de álgebra en tu app de estudio.',
      'categoria': 'cognitiva',
      'puntos': 150,
      'tiempo_estimado_minutos': 20,
      'estado': 'activo',
      'hijo_id': 'hijo_juan',
      'fecha_creacion': '2026-06-04T10:00:00.000Z',
      'fecha_completado': null,
    };

    test('1. Debería construir una instancia perfecta desde fromJson', () {
      final desafio = Desafio.fromJson(jsonCompleto);

      expect(desafio.id, 'desafio_001');
      expect(desafio.titulo, 'Resolver 5 problemas de matemática');
      expect(desafio.categoria, 'cognitiva');
      expect(desafio.puntos, 150);
      expect(desafio.tiempoEstimadoMinutos, 20);
      expect(desafio.estado, 'activo');
      expect(desafio.hijoId, 'hijo_juan');
      expect(desafio.fechaCreacion, isA<DateTime>());
      expect(desafio.fechaCompletado, null);
    });

    test(
      '2. Debe manejar casteo seguro de números float a enteros y valores por defecto',
      () {
        final Map<String, dynamic> jsonConFloatsYNulos = {
          'id': 'desafio_002',
          'puntos': 100.5, // El backend envía un float sin querer
          'tiempo_estimado_minutos': 15.0,
          'categoria': null, // Viene nulo
        };

        final desafio = Desafio.fromJson(jsonConFloatsYNulos);

        // Verificamos que el as num.toInt() haga su magia de protección
        expect(desafio.puntos, 100);
        expect(desafio.tiempoEstimadoMinutos, 15);
        expect(
          desafio.categoria,
          'general',
        ); // Valor por defecto asignado en fromJson
      },
    );

    test('3. El método toJson debe omitir llaves opcionales si son nulas', () {
      final desafioSimple = Desafio(
        id: '99',
        titulo: 'Ordenar la pieza',
        descripcion: 'Dejar los juguetes en su caja',
        categoria: 'hogar',
        puntos: 50,
        // hijoId y fechas se quedan como null
      );

      final jsonResultante = desafioSimple.toJson();

      expect(jsonResultante['id'], '99');
      expect(jsonResultante['puntos'], 50);
      // Validamos que los condicionales inline del mapa funcionaran
      expect(jsonResultante.containsKey('hijo_id'), false);
      expect(jsonResultante.containsKey('fecha_creacion'), false);
    });

    test(
      '4. Los getters de estado (estaActivo, estaPendiente, estaCompletado) deben ser precisos',
      () {
        final desafio = Desafio(
          id: '1',
          titulo: 'Prueba',
          descripcion: 'Prueba',
          categoria: 'fisica',
          puntos: 10,
          estado: 'ActIvO', // Lo pasamos mezclando mayúsculas a propósito
        );

        // Evalúa que el toLowerCase() de tu modelo funcione correctamente
        expect(desafio.estaActivo, true);
        expect(desafio.estaPendiente, false);
        expect(desafio.estaCompletado, false);
      },
    );

    test(
      '5. El getter tiempoTexto debe formatear correctamente la duración para la interfaz',
      () {
        final desafioConTiempo = Desafio(
          id: '1',
          titulo: 'A',
          descripcion: 'B',
          categoria: 'C',
          puntos: 10,
          tiempoEstimadoMinutos: 45, // 👈 Cambiado a 'Estimado'
        );

        final desafioSinTiempo = Desafio(
          id: '2',
          titulo: 'A',
          descripcion: 'B',
          categoria: 'C',
          puntos: 10,
          tiempoEstimadoMinutos: 0, // 👈 Cambiado a 'Estimado'
        );

        expect(desafioConTiempo.tiempoTexto, '45 min');
        expect(desafioSinTiempo.tiempoTexto, 'Sin límite');
      },
    );

    test(
      '6. El método copyWith debe clonar la información de forma inmutable',
      () {
        final original = Desafio(
          id: 'id_orig',
          titulo: 'Original',
          descripcion: 'D',
          categoria: 'C',
          puntos: 10,
          estado: 'pendiente',
        );

        final modificado = original.copyWith(estado: 'completado', puntos: 500);

        expect(modificado.id, 'id_orig'); // Mismo ID
        expect(modificado.estado, 'completado'); // Cambió
        expect(modificado.puntos, 500); // Cambió
      },
    );

    test('7. fromJson con fecha_completado no nula parsea la fecha correctamente', () {
      final json = {
        'id': '1',
        'titulo': 'Reto',
        'descripcion': 'D',
        'categoria': 'fisica',
        'puntos': 50,
        'fecha_completado': '2026-05-10T12:00:00Z',
      };
      final desafio = Desafio.fromJson(json);
      expect(desafio.fechaCompletado, isA<DateTime>());
    });

    test('8. copyWith sin puntos ni estado usa los valores de la instancia', () {
      final original = Desafio(
        id: '1',
        titulo: 'T',
        descripcion: 'D',
        categoria: 'C',
        puntos: 99,
        estado: 'activo',
      );
      // Solo cambia titulo: puntos y estado quedan null → this.X evaluado
      final clone = original.copyWith(titulo: 'Nuevo título');
      expect(clone.puntos, 99);
      expect(clone.estado, 'activo');
    });

    test('9. toString retorna representación con titulo', () {
      final d = Desafio(id: '1', titulo: 'Mi Desafío', descripcion: 'D', categoria: 'C', puntos: 10);
      expect(d.toString(), contains('Mi Desafío'));
    });
  });
}
