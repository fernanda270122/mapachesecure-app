import 'package:flutter_test/flutter_test.dart';
import 'package:mapachesecure_app/services/guardian_service.dart';

void main() {
  group('Pruebas unitarias para ReglaBloqueo (Gestión de reglas)', () {
    test(
      '1. Regla con horario válido se construye correctamente desde JSON',
      () {
        final json = {
          'hora_inicio': '08:00',
          'hora_fin': '12:00',
          'dias_semana': '[0, 1, 2, 3, 4]',
          'package_names': 'com.tiktok.app,com.instagram.android',
        };

        final regla = ReglaBloqueo.fromJson(json);

        expect(regla.inicio, '08:00');
        expect(regla.fin, '12:00');
        expect(regla.dias, containsAll([0, 1, 2, 3, 4]));
        expect(regla.appsAfectadas, contains('com.tiktok.app'));
      },
    );

    test('2. Regla sin apps afectadas retorna lista vacía', () {
      final json = {
        'hora_inicio': '20:00',
        'hora_fin': '22:00',
        'dias_semana': '[0]',
        'package_names': '',
      };

      final regla = ReglaBloqueo.fromJson(json);

      expect(regla.appsAfectadas.isEmpty, true);
    });

    test('3. Regla con múltiples días los parsea todos correctamente', () {
      final json = {
        'hora_inicio': '14:00',
        'hora_fin': '18:00',
        'dias_semana': '[0, 1, 2, 3, 4, 5, 6]',
        'package_names': 'com.roblox.client',
      };

      final regla = ReglaBloqueo.fromJson(json);

      expect(regla.dias.length, 7);
      expect(regla.dias, containsAll([0, 1, 2, 3, 4, 5, 6]));
    });

    test('4. Regla con horario de medianoche se maneja correctamente', () {
      final json = {
        'hora_inicio': '22:00',
        'hora_fin': '23:59',
        'dias_semana': '[4, 5]',
        'package_names': 'com.youtube.android',
      };

      final regla = ReglaBloqueo.fromJson(json);

      expect(regla.inicio, '22:00');
      expect(regla.fin, '23:59');
      expect(regla.dias, containsAll([4, 5]));
      expect(regla.appsAfectadas, contains('com.youtube.android'));
    });
  });
}
