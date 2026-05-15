import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _loginChannelId = 'login_channel';
  static const _loginChannelName = 'Notificaciones de Sesión';

  /// Solo inicializa el plugin y los listeners. No toca el backend.
  Future<void> init() async {
    await _initLocalNotifications();
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen(_mostrarNotificacionFCM);
  }

  /// Envía el token FCM al backend. Llamar DESPUÉS del login.
  Future<void> registrarToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _api.post('/notificaciones/token', {'fcm_token': token});
      }
    } catch (_) {
      // Si falla el registro del token, no interrumpimos el flujo de la app
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // Canal dedicado para notificaciones de sesión
    const AndroidNotificationChannel loginChannel = AndroidNotificationChannel(
      _loginChannelId,
      _loginChannelName,
      description: 'Aviso cuando inicias sesión en MapacheSecure',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(loginChannel);
  }

  /// Muestra una notificación local confirmando el inicio de sesión.
  Future<void> mostrarNotificacionLogin(String nombre, String rol) async {
    final rolTexto = rol == 'padre' ? 'Padre' : 'Hijo';

    await _localNotifications.show(
      id: 100,
      title: 'Sesión iniciada correctamente',
      body: 'Bienvenido, $nombre ($rolTexto) — MapacheSecure',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _loginChannelId,
          _loginChannelName,
          channelDescription: 'Aviso cuando inicias sesión en MapacheSecure',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _mostrarNotificacionFCM(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mapache_channel',
          'Guardián MapacheSecure',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
