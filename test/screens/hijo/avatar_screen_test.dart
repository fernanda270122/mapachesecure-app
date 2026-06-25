import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/screens/hijo/avatar_screen.dart';

//PRUEBAS UNITARIAS PARA FOTO DE PERFIL
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget crearEntorno() {
    return ChangeNotifierProvider(
      create: (_) => TemaProvider(),
      child: const MaterialApp(home: AvatarScreen()),
    );
  }

  group('Pruebas unitarias para AvatarScreen (Foto de perfil)', () {
    testWidgets(
      '1. La galería debe mostrar exactamente 7 opciones de avatar disponibles',
      (WidgetTester tester) async {
        await tester.pumpWidget(crearEntorno());
        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsNWidgets(6));
      },
    );
    testWidgets(
      '2. Sin avatar guardado, el valor inicial debe ser nulo (ninguno seleccionado)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(crearEntorno());
        await tester.pumpAndSettle();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final haySeleccionado = containers.any((c) {
          final deco = c.decoration;
          if (deco is BoxDecoration && deco.border != null) {
            final border = deco.border as Border;
            return border.top.color == Colors.deepPurple;
          }
          return false;
        });

        expect(haySeleccionado, false);
      },
    );
    testWidgets(
      '3. Al cargar con avatar previo guardado, debe marcarse como seleccionado',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'avatar_hijo': 'assets/avatares/perfil2.jpeg',
        });

        await tester.pumpWidget(crearEntorno());
        await tester.pumpAndSettle();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final haySeleccionado = containers.any((c) {
          final deco = c.decoration;
          if (deco is BoxDecoration && deco.border != null) {
            final border = deco.border as Border;
            return border.top.color == Colors.deepPurple;
          }
          return false;
        });

        expect(haySeleccionado, true);
      },
    );

    testWidgets(
      '4. Seleccionar un avatar debe persistirlo inmediatamente en SharedPreferences',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({'user_id': 'hijo_test_123'});

        await tester.pumpWidget(crearEntorno());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('avatar_hijo'), 'assets/avatares/perfil1.jpeg');
      },
    );
  });
}
