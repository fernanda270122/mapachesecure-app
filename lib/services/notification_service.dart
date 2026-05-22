import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Handler de mensajes en background (app cerrada o en segundo plano).
// Debe ser una función top-level (fuera de cualquier clase) — requisito de Firebase.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  // Mostramos la notificación localmente cuando llega en background
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.show(
    id: message.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'mapache_channel', // Debe coincidir con el canal creado en init()
        'Guardián Raccu',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal para el aviso de inicio de sesión
  static const _loginChannelId = 'login_channel';
  static const _loginChannelName = 'Notificaciones de Sesión';

  // Canal para notificaciones de evidencias y desafíos (FCM)
  static const _mainChannelId = 'mapache_channel';
  static const _mainChannelName = 'Guardián Raccu';

  /// Inicializa canales, permisos y listeners. Se llama en main() al arrancar la app.
  Future<void> init() async {
    await _initLocalNotifications();
    await _messaging.requestPermission();

    // Listener para mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_mostrarNotificacionFCM);

    // Registrar el handler de background (app cerrada o minimizada)
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  }

  /// Envía el token FCM al backend. Llamar DESPUÉS del login.
  Future<void> registrarToken() async {
    try {
      final token = await _messaging.getToken();
      print('[FCM] Token obtenido: $token');
      if (token != null) {
        await _api.post('/notificaciones/token', {'fcm_token': token});
        print('[FCM] Token registrado en backend correctamente');
      } else {
        print('[FCM] Token es null — no se pudo obtener');
      }
    } catch (e) {
      print('[FCM] Error al registrar token: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // En Android 8+ los canales deben crearse antes de usarlos,
    // si no existen las notificaciones simplemente no aparecen
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Canal para el aviso de inicio de sesión
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _loginChannelId,
        _loginChannelName,
        description: 'Aviso cuando inicias sesión en Raccu',
        importance: Importance.high,
      ),
    );

    // Canal para evidencias y validaciones — usado por el handler de FCM
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _mainChannelId,
        _mainChannelName,
        description: 'Notificaciones de evidencias y desafíos',
        importance: Importance.high,
      ),
    );
  }

  /// Muestra una notificación local confirmando el inicio de sesión.
  Future<void> mostrarNotificacionLogin(String nombre, String rol) async {
    final rolTexto = rol == 'padre' ? 'Padre' : 'Hijo';

    await _localNotifications.show(
      id: 100,
      title: 'Sesión iniciada correctamente',
      body: 'Bienvenido, $nombre ($rolTexto) — Raccu',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _loginChannelId,
          _loginChannelName,
          channelDescription: 'Aviso cuando inicias sesión en Raccu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Muestra notificaciones FCM cuando la app está en primer plano
  Future<void> _mostrarNotificacionFCM(RemoteMessage message) async {
    final notification = message.notification;
    print('[FCM] Mensaje recibido en foreground: ${message.messageId}');
    if (notification == null) {
      print('[FCM] Sin campo notification en el mensaje');
      return;
    }
    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _mainChannelId,
            _mainChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      print('[FCM] Notificacion local mostrada correctamente');
    } catch (e) {
      print('[FCM] Error al mostrar notificacion local: $e');
    }
  }
}
