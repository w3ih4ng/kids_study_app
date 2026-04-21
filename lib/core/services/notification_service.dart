import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Background handler — do NOT show local notification here
// FCM already auto-displays notification messages in background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Only handle data-only messages (no notification payload)
  if (message.notification == null) {
    await NotificationService.showLocalNotification(message);
  }
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  static const _channelId = 'kids_study_app';
  static const _channelName = 'Kids Study App';

  static Future<void> initialize() async {
    await _messaging.requestPermission(
        alert: true, badge: true, sound: true);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Foreground — FCM does NOT auto-show, so we show manually
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(message);
    });
  }

  static Future<void> showLocalNotification(
      RemoteMessage message) async {
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

  // Save FCM token — cleans up old tokens for this device first
  static Future<void> saveToken(String childId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    // Delete any existing row with this exact token
    // (in case it was registered under a different child)
    await _supabase
        .from('device_tokens')
        .delete()
        .eq('token', token);

    // Insert fresh
    await _supabase.from('device_tokens').insert({
      'child_id': childId,
      'token': token,
    });
  }

  static Future<void> removeToken(String childId) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _supabase
        .from('device_tokens')
        .delete()
        .eq('child_id', childId)
        .eq('token', token);
  }

  static Future<void> notifyAll({
    required String title,
    required String body,
  }) async {
    try {
      final response = await _supabase
          .from('device_tokens')
          .select('token');

      final tokens = (response as List)
          .map((e) => e['token'] as String)
          .toSet() // deduplicate just in case
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
        body: {'token': token, 'title': title, 'body': body},
        headers: {
          'Authorization':
          'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}