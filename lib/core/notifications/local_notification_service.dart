import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    const channel = AndroidNotificationChannel(
      'default_channel',
      'Notificaciones Red Cristiana',
      description: 'Canal principal de notificaciones',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notificaciones Red Cristiana',
      channelDescription: 'Canal principal de notificaciones',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}