import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/onboarding/onboarding_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas para OnboardingScreen', () {
    testWidgets(
      '1. Rol padre muestra el slide inicial de bienvenida correcto',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'padre', destino: SizedBox()),
        ));
        await tester.pump();
        expect(find.text('¡Bienvenido a Raccu!'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Rol hijo muestra el slide inicial de bienvenida correcto',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'hijo', destino: SizedBox()),
        ));
        await tester.pump();
        expect(find.text('¡Hola! Bienvenido a Raccu'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Botón "Saltar" está visible en pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'padre', destino: SizedBox()),
        ));
        await tester.pump();
        expect(find.text('Saltar'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Primer slide muestra botón "Siguiente", no "¡Comenzar!"',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'padre', destino: SizedBox()),
        ));
        await tester.pump();
        expect(find.text('Siguiente'), findsOneWidget);
        expect(find.text('¡Comenzar!'), findsNothing);
      },
    );

    testWidgets(
      '5. PageView está presente en la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'hijo', destino: SizedBox()),
        ));
        await tester.pump();
        expect(find.byType(PageView), findsOneWidget);
      },
    );

    testWidgets(
      '6. Slides de padre contienen texto de descripción del primer slide',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'padre', destino: SizedBox()),
        ));
        await tester.pump();
        expect(
          find.textContaining('Protege el tiempo digital'),
          findsOneWidget,
        );
      },
    );
  });
}
