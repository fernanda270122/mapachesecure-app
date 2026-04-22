import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
    final FirebaseMessaging _messaging = FirebaseMessaging.instance;
    final ApiService _api = ApiService();

    Future<void> init() async {
      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      if (token != null) {
        await _api.post('/notificaciones/token', {'fcm_token': token});
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Notificación recibida: ${message.notification?.title}');
      });
    }
  }