import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/services/auth_service.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas de integración — MapacheSecure', () {
    test(
      '1. AuthService.isLoggedIn y getRol leen correctamente desde SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'token': 'access_123',
          'rol': 'padre',
        });

        final authService = AuthService();

        expect(await authService.isLoggedIn(), true);
        expect(await authService.getRol(), 'padre');
      },
    );

    testWidgets(
      '2. Seleccionar un avatar en la pantalla actualiza SharedPreferences correctamente',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({'user_id': 'hijo_test_001'});

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => TemaProvider(),
            child: const MaterialApp(home: AvatarScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('avatar_hijo'), isNotNull);
      },
    );

    test('3. TemaProvider persiste y recupera el tema correctamente', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = TemaProvider();
      await provider.cambiar('Océano');

      final provider2 = TemaProvider();
      await provider2.cargar();

      expect(provider2.paleta, 'Océano');
    });

    test(
      '4. TemaProvider y TemaPadreProvider almacenan en claves independientes sin interferirse',
      () async {
        SharedPreferences.setMockInitialValues({});

        final temaHijo = TemaProvider();
        final temaPadre = TemaPadreProvider();

        await temaHijo.cambiar('Océano');
        await temaPadre.cambiarTemaPadre('Bosque Oscuro');

        final nuevoHijo = TemaProvider();
        final nuevoPadre = TemaPadreProvider();
        await nuevoHijo.cargar();
        await nuevoPadre.cargarTemaPadre();

        expect(nuevoHijo.paleta, 'Océano');
        expect(nuevoPadre.paletaPadre, 'Bosque Oscuro');
      },
    );
  });
}
