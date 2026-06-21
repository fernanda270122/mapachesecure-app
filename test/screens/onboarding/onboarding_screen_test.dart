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

    testWidgets(
      '7. Tap "Siguiente" avanza de página y dispara onPageChanged',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(rol: 'padre', destino: SizedBox()),
        ));
        await tester.pump();
        await tester.tap(find.text('Siguiente'));
        // pumpAndSettle: espera animación PageView (300ms) + AnimatedContainer (300ms)
        await tester.pumpAndSettle();
        expect(find.text('Agrega a tus hijos'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Tap "Saltar" llama _terminar() y navega al destino',
      (tester) async {
        await tester.pumpWidget(_wrap(
          OnboardingScreen(
            rol: 'hijo',
            destino: const Scaffold(body: Text('Pantalla Inicio')),
            userId: 'test-uid',
          ),
        ));
        await tester.pump();
        await tester.tap(find.text('Saltar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pantalla Inicio'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Navegar hasta el último slide de hijo y tap "¡Comenzar!" navega al destino',
      (tester) async {
        await tester.pumpWidget(_wrap(
          const OnboardingScreen(
            rol: 'hijo',
            destino: Scaffold(body: Text('Destino Final')),
          ),
        ));
        await tester.pump();
        // hijo tiene 5 slides (índice 0-4), avanzar 4 veces
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Siguiente'));
          await tester.pumpAndSettle();
        }
        expect(find.text('¡Comenzar!'), findsOneWidget);
        await tester.tap(find.text('¡Comenzar!'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Destino Final'), findsOneWidget);
      },
    );
  });
}
