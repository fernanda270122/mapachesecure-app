import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/registro_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para RegistroScreen', () {
    testWidgets(
      '1. Muestra el título "Crea tu cuenta"',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Crea tu cuenta'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra el subtítulo "Únete a la familia Raccu"',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Únete a la familia Raccu'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra campo "Nombre Completo"',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Nombre Completo'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Muestra campo "Correo Electrónico"',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Correo Electrónico'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra el botón "REGISTRARSE"',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
        await tester.pumpAndSettle();
        expect(find.text('REGISTRARSE'), findsOneWidget);
      },
    );
  });
}
