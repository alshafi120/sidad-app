/// Notification Service using flutter_local_notifications for custom sounds.
/// Note: Firebase Messaging should be integrated here once google-services.json is available.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService().._init();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    _createChannels();
  }

  void _createChannels() {
    // Channel for standard alerts
    const standardChannel = AndroidNotificationChannel(
      'sidad_general',
      'General Alerts',
      description: 'System alerts and general notifications',
      importance: Importance.high,
      playSound: true,
    );

    // Channel for high-priority payment received (needs a custom sound in android/app/src/main/res/raw/cash_register.mp3)
    const paymentChannel = AndroidNotificationChannel(
      'sidad_payments',
      'Payment Received',
      description: 'Notifications for successful payments',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('cash_register'),
    );

    _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(standardChannel);

    _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);
  }

  /// Trigger a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'sidad_general',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'sidad_payments' ? 'Payment Received' : 'General Alerts',
      importance: Importance.max,
      priority: Priority.high,
      sound: channelId == 'sidad_payments' 
          ? const RawResourceAndroidNotificationSound('cash_register')
          : null,
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: channelId == 'sidad_payments' ? 'cash_register.caf' : null,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
