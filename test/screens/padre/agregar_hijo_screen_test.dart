import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:mapachesecure_app/screens/padre/agregar_hijo_screen.dart';
import 'package:mapachesecure_app/services/api_service.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.testClient = MockClient((req) async => http.Response('{"ok": true}', 200));
  });

  tearDown(() {
    ApiService.testClient = null;
  });

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

  group('Pruebas de validacion del formulario', () {
    Future<void> cargar(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
    }

    testWidgets('5. Muestra error cuando el nombre esta vacio', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      expect(find.text('Ingresa el nombre'), findsOneWidget);
    });

    testWidgets('6. Muestra error cuando el correo no tiene arroba', (tester) async {
      await cargar(tester);
      await tester.enterText(find.ancestor(of: find.text('Nombre Completo'), matching: find.byType(TextFormField)), 'Lucas');
      await tester.enterText(find.ancestor(of: find.text('Correo Electrónico'), matching: find.byType(TextFormField)), 'sinArroba.com');
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      expect(find.text('Correo no válido'), findsOneWidget);
    });

    testWidgets('7. Muestra error cuando la contrasena tiene menos de 6 caracteres', (tester) async {
      await cargar(tester);
      await tester.enterText(find.ancestor(of: find.text('Nombre Completo'), matching: find.byType(TextFormField)), 'Lucas');
      await tester.enterText(find.ancestor(of: find.text('Correo Electrónico'), matching: find.byType(TextFormField)), 'test@test.com');
      await tester.enterText(find.ancestor(of: find.text('Contraseña'), matching: find.byType(TextFormField)), 'abc');
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('8. Muestra error cuando la edad esta fuera del rango valido', (tester) async {
      await cargar(tester);
      await tester.enterText(find.ancestor(of: find.text('Nombre Completo'), matching: find.byType(TextFormField)), 'Lucas');
      await tester.enterText(find.ancestor(of: find.text('Correo Electrónico'), matching: find.byType(TextFormField)), 'test@test.com');
      await tester.enterText(find.ancestor(of: find.text('Contraseña'), matching: find.byType(TextFormField)), 'password123');
      await tester.enterText(find.ancestor(of: find.text('Edad'), matching: find.byType(TextFormField)), '25');
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      expect(find.text('Edad debe ser entre 1 y 18 años'), findsOneWidget);
    });

    testWidgets('9. Muestra los chips de intereses en el formulario', (tester) async {
      await cargar(tester);
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('Videojuegos'), findsOneWidget);
    });

    testWidgets('10. Seleccionar un chip de interes lo marca como activo', (tester) async {
      await cargar(tester);
      await tester.tap(find.text('Videojuegos'));
      await tester.pump();
      final chip = tester.widget<FilterChip>(
        find.ancestor(of: find.text('Videojuegos'), matching: find.byType(FilterChip)),
      );
      expect(chip.selected, true);
    });
  });

  group('Pruebas de registro con API', () {
    Future<void> llenarFormularioValido(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(find.ancestor(of: find.text('Nombre Completo'), matching: find.byType(TextFormField)), 'Lucas');
      await tester.enterText(find.ancestor(of: find.text('Correo Electrónico'), matching: find.byType(TextFormField)), 'lucas@test.com');
      await tester.enterText(find.ancestor(of: find.text('Contraseña'), matching: find.byType(TextFormField)), 'password123');
      await tester.enterText(find.ancestor(of: find.text('Edad'), matching: find.byType(TextFormField)), '10');
    }

    testWidgets('11. Registro exitoso muestra dialogo de confirmacion', (tester) async {
      await llenarFormularioValido(tester);
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('¡Hijo registrado!'), findsOneWidget);
    });

    testWidgets('12. Error 400 muestra mensaje de correo ya registrado', (tester) async {
      // Respuesta JSON vacia con status 400: ApiService lanza Exception('Error del servidor (400)')
      // que contiene '400', activando el mensaje personalizado
      ApiService.testClient = MockClient((req) async => http.Response('{}', 400));
      await llenarFormularioValido(tester);
      await tester.tap(find.text('Registrar e Iniciar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('El correo ya está registrado'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
