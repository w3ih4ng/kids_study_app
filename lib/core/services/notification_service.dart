import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  static const _channelId = 'kids_study_app';
  static const _channelName = 'Kids Study App';

  // Call this once on app start
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications channel (Android)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(message);
    });
  }

  // Show local notification
  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Save FCM token for current child
  static Future<void> saveToken(String childId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _supabase.from('device_tokens').upsert({
      'child_id': childId,
      'token': token,
    }, onConflict: 'child_id, token');
  }

  // Remove token when child logs out
  static Future<void> removeToken(String childId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _supabase
        .from('device_tokens')
        .delete()
        .eq('child_id', childId)
        .eq('token', token);
  }

  // Send notification to all devices (called when admin adds lesson/quiz)
  static Future<void> notifyAll({
    required String title,
    required String body,
  }) async {
    try {
      final response =
      await _supabase.from('device_tokens').select('token');
      final tokens = (response as List)
          .map((e) => e['token'] as String)
          .toList();

      if (tokens.isEmpty) return;

      for (final token in tokens) {
        await _sendFCM(token: token, title: title, body: body);
      }
    } catch (e) {
      debugPrint('NotifyAll error: $e');
    }
  }

  static Future<void> _sendFCM({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
        },
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
      );
    } catch (e) {
      // Don't let notification failure block the main action
      debugPrint('Notification error: $e');
    }
  }
}