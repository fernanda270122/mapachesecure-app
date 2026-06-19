import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/consejos_padres_screen.dart';

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: ConsejosPadresScreen()),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para ConsejosPadresScreen', () {
    testWidgets(
      '1. Muestra "Consejos para Padres" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Consejos para Padres'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra la sección de instalación',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('¿Cómo instalar la app en el celular de tu hijo?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. Al hacer scroll muestra la sección sobre desafíos',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('¿Cómo funcionan los desafíos?'),
          300.0,
        );
        expect(find.text('¿Cómo funcionan los desafíos?'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Al hacer scroll muestra la sección sobre la mascota Raccu',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('La mascota Raccu'), 300.0);
        expect(find.text('La mascota Raccu'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Muestra al menos 1 tarjeta de sección visible en el viewport',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      },
    );
  });
}
