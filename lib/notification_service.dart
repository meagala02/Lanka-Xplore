import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Background handler (top-level — class-க்கு வெளியே இருக்கணும்) ──────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

// ─── NotificationService ──────────────────────────────────────────────────────
class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'lankaxplore_channel';
  static const _channelName = 'LankaXplore Notifications';

  // ── Initialize (main.dart-ல் call பண்ணுங்கள்) ──────────────────────────────
  static Future<void> initialize() async {
    // 1. Background handler register
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Permission request
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Android notification channel create
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'LankaXplore app notifications',
      importance: Importance.high,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Local notification plugin initialize
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // 5. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    debugPrint('[FCM] NotificationService initialized');
  }

  // ── FCM Token-ஐ Firestore-ல் save பண்ணு ────────────────────────────────────
  static Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('[FCM] Token saved for $userId');
      }
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  // ── Welcome notification அனுப்பு (registration-ல் call பண்ணுங்கள்) ─────────
  static Future<void> sendWelcomeNotification(String userId) async {
    try {
      // Firestore-ல் notification document create பண்ணு
      // Cloud Function இதை trigger பண்ணி FCM push அனுப்பும்
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': '🌴 Welcome to LankaXplore!',
        'body':
            'You have successfully registered. Explore the beauty of Sri Lanka!',
        'type': 'welcome',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[FCM] Welcome notification created for $userId');
    } catch (e) {
      debugPrint('[FCM] Welcome notification error: $e');
    }
  }

  // ── Local notification show (app foreground-ல் இருக்கும்போது) ──────────────
  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF009688), // Teal color
        ),
      ),
    );
  }
}
