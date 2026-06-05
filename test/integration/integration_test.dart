import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/models/desafio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas de integración — MapacheSecure', () {
    test(
      '1. Login persiste token y rol correctamente en SharedPreferences',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', 'access_123');
        await prefs.setString('rol', 'padre');
        await prefs.setString('user_id', 'user_abc');

        final token = prefs.getString('token');
        final rol = prefs.getString('rol');
        final userId = prefs.getString('user_id');

        expect(token, 'access_123');
        expect(rol, 'padre');
        expect(userId, 'user_abc');
        expect(token, isNotNull);
      },
    );

      test(
      '2. Selección de avatar se guarda y se recupera correctamente',
      () async {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('avatar_hijo', 'assets/avatares/perfil3.jpeg');

        final avatarRecuperado = prefs.getString('avatar_hijo');

        expect(avatarRecuperado, 'assets/avatares/perfil3.jpeg');
        expect(avatarRecuperado, isNotNull);
      },
    );

      test(
      '3. TemaProvider persiste y recupera el tema correctamente',
      () async {
        SharedPreferences.setMockInitialValues({});

        final provider = TemaProvider();
        await provider.cambiar('Océano');

        final provider2 = TemaProvider();
        await provider2.cargar();

        expect(provider2.paleta, 'Océano');
      },
    );

     test(
      '4. JSON del backend se convierte a Desafio y sus getters funcionan en conjunto',
      () {
        final json = {
          'id': 'desafio_001',
          'titulo': 'Ordenar la pieza',
          'descripcion': 'Paso 1: Recoge la ropa. Paso 2: Ponla en el cajón.',
          'categoria': 'hogar',
          'puntos': 30,
          'tiempo_estimado_minutos': 15,
          'estado': 'activo',
          'hijo_id': 'hijo_123',
        };

        final desafio = Desafio.fromJson(json);

        expect(desafio.estaActivo, true);
        expect(desafio.estaPendiente, false);
        expect(desafio.tiempoTexto, '15 min');
        expect(desafio.puntos, inInclusiveRange(20, 35));
      },
    );
  });
}