import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation/tab_navigation.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

const _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications importantes',
  importance: Importance.high,
);

Future<void> initNotifications() async {
  final launchDetails = await _localNotifications
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    openNotificationTab();
  }

  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_channel);

  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (_) => openNotificationTab(),
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  FirebaseMessaging.onMessageOpenedApp.listen((_) => openNotificationTab());

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    openNotificationTab();
  }
}

void _showForegroundNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;

  final data = message.data;

  if (data['type'] == 'dhikr') {
    debugPrint('Received dhikr notification: ${notification.title}');
    debugPrint('Merge result: ${data['mergeResult']}');
  }

  _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: 'notification-tab',
  );
}
