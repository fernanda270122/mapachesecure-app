import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/canjes_pendientes_screen.dart';

Widget _wrap() => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TemaPadreProvider(),
        child: const MaterialApp(home: CanjesPendientesScreen()),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 'padre-uid'});
  });

  group('Pruebas para CanjesPendientesScreen', () {
    testWidgets(
      '1. Muestra "Canjes Pendientes" en el AppBar',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.text('Canjes Pendientes'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Muestra mensaje de lista vacía cuando no hay canjes',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(
          find.text('No hay canjes esperando aprobación'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. Contiene un Scaffold como raíz de la pantalla',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      '4. Contiene SafeArea en el cuerpo',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      },
    );
  });
}
