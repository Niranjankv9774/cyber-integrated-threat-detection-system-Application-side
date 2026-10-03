import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Singleton service for showing real Android system tray notifications.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification plugin. Call once in main().
  Future<void> init() async {
    if (_initialized) return;

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped the notification — can navigate here if needed
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request permission on Android 13+
    await _requestPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Request notification permission (Android 13+ / API 33+)
  Future<void> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  /// Show a system notification in the tray.
  /// [id] must be unique per notification (use the notification DB id).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cyber_alerts',                  // Channel ID
      'CyberIntegrated Alerts',        // Channel Name
      channelDescription: 'Notifications from CyberIntegrated admin',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),  // Expandable text
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: id.toString(),
    );
  }
}
