import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/agregar_hijo_screen.dart';

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: AgregarHijoScreen()),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas para AgregarHijoScreen', () {
    testWidgets(
      '1. Muestra "Agregar Hij@" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Agregar Hij@'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra la sección "Datos de Cuenta"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Datos de Cuenta'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Muestra campo "Nombre Completo"',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.text('Nombre Completo'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Contiene un formulario (Form widget)',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byType(Form), findsOneWidget);
      },
    );
  });
}
