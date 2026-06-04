import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapachesecure_app/screens/auth/login_screen.dart';

void main() {
  // Limpiamos y mockeamos la persistencia local antes de cada test
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Contenedor seguro para renderizar la pantalla simulando el árbol de navegación
  Widget crearEntornoSeguro(Widget pantalla) {
    return MaterialApp(home: pantalla);
  }

  group('Suite Completa de Widget Tests para LoginScreen', () {
    testWidgets(
      '1. Verificación de Interfaz: Deben renderizarse todos los componentes corporativos',
      (WidgetTester tester) async {
        await tester.pumpWidget(crearEntornoSeguro(const LoginScreen()));

        // Comprobamos el título principal
        expect(find.text('Iniciar Sesión'), findsOneWidget);

        // Verificamos los campos de entrada por su texto de ayuda (hint)
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.hintText == 'Correo electrónico',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Contraseña',
          ),
          findsOneWidget,
        );

        // Verificamos que los botones de acción existan textualmente con tu diseño premium
        expect(find.text('INGRESAR'), findsOneWidget);
        expect(find.text('CREAR CUENTA'), findsOneWidget);
        expect(find.text('Olvidé mi contraseña'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Simulación de Entrada: El usuario debe poder escribir sus credenciales en las cajas de texto',
      (WidgetTester tester) async {
        await tester.pumpWidget(crearEntornoSeguro(const LoginScreen()));

        final inputs = find.byType(TextField);
        expect(inputs, findsNWidgets(2)); // Correo y Clave

        // Escribimos datos simulados en la UI virtual
        await tester.enterText(inputs.first, 'javier.padre@mapache.com');
        await tester.enterText(inputs.last, 'raccuContrasena123');

        // Forzamos el rediseño del frame de Flutter para actualizar el estado visual
        await tester.pump();

        // Certificamos que el árbol visual retiene lo que el usuario escribió
        expect(find.text('javier.padre@mapache.com'), findsOneWidget);
        expect(find.text('raccuContrasena123'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Flujo Alternativo (Error de Red): Datos vacíos o erróneos deben pintar la advertencia en rojo',
      (WidgetTester tester) async {
        await tester.pumpWidget(crearEntornoSeguro(const LoginScreen()));

        // Buscamos el botón de ingreso directo
        final botonIngresar = find.text('INGRESAR');

        // Presionamos el botón sin rellenar los datos (forzando el catch de tu código)
        await tester.tap(botonIngresar);

        // Esperamos a que se resuelvan los hilos asíncronos y animaciones pendientes
        await tester.pumpAndSettle();

        // Validamos que tu estado reactivo '_error' pintó con éxito la alerta esperada
        expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Simulación del Diálogo del Guardián: Validar estructura de "Autorización Requerida"',
      (WidgetTester tester) async {
        await tester.pumpWidget(crearEntornoSeguro(const LoginScreen()));

        // Conseguimos la instancia del estado de la pantalla para invocar directamente tu popup protector
        final State<LoginScreen> loginState = tester.state(
          find.byType(LoginScreen),
        );

        // Ejecutamos tu función nativa que abre el AlertDialog de desactivación
        // Usamos el contexto del árbol virtual
        final loginScreenState = loginState as dynamic;

        // Lanzamos el diálogo de seguridad en el hilo de pruebas
        tester.runAsync(() async {
          loginScreenState.intentarCerrarSesion(loginState.context);
        });

        // Forzamos a Flutter a abrir el modal
        await tester.pumpAndSettle();

        // Certificamos que el candado de seguridad se despliega correctamente ante el usuario
        expect(find.text('Autorización Requerida'), findsOneWidget);
        expect(
          find.text(
            'Para desactivar el Guardián, un adulto debe ingresar sus credenciales de acceso.',
          ),
          findsOneWidget,
        );
        expect(find.text('Correo del Adulto'), findsOneWidget);
        expect(find.text('CANCELAR'), findsOneWidget);
        expect(find.text('DESACTIVAR GUARDIÁN'), findsOneWidget);
      },
    );
  });
}
