import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:red_cristiana/core/notifications/app_refresh_bus.dart';
import 'package:red_cristiana/core/notifications/in_app_notification_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_cristiana/core/notifications/local_notification_service.dart';

class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final _client = Supabase.instance.client;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('PushService.init()');

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Permiso push: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error pidiendo permiso: $e');
    }

    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token actual: $token');

      final user = _client.auth.currentUser;
      if (user != null && token != null && token.isNotEmpty) {
        await _client.from('user_push_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': _platformName(),
        });
      }
    } catch (e) {
      debugPrint('Error guardando token: $e');
    }

    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('Token refrescado: $token');

      try {
        final user = _client.auth.currentUser;
        if (user == null) return;

        await _client.from('user_push_tokens').upsert({
          'user_id': user.id,
          'token': token,
          'platform': _platformName(),
        });
      } catch (e) {
        debugPrint('Error guardando token refrescado: $e');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('==============================');
      debugPrint('Mensaje foreground recibido');
      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
      debugPrint('==============================');

      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'Nueva notificación';

      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          '';

      InAppNotificationBanner.show(
        title: title,
        body: body,
      );

      final type = message.data['type']?.toString().toLowerCase() ?? '';

      if (type == 'post' || type == 'event' || type == 'video') {
        AppRefreshBus.emit('feed_refresh');
      } else {
        AppRefreshBus.emit('general_refresh');
      }
    });
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}