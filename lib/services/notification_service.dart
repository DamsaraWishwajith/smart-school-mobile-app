import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[FCM LOG] Background message received: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging, Local Notifications & Setup Listeners
  static Future<void> initialize() async {
    try {
      debugPrint("[FCM LOG] Initializing NotificationService...");
      
      // 1. Request Notification Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM LOG] User granted permission status: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications for Foreground Pop-up Banners
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("[FCM LOG] Local Notification Clicked: ${response.payload}");
        },
      );

      // Create Android High Importance Notification Channel for Real-Time Banners
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for real-time notifications.',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // 3. Set Background Messaging Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Handle Foreground Messages (Show Real-Time Pop-Up Banner & Sound while inside App!)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM LOG] Real-time Foreground Message received! Title: ${message.notification?.title}, Data: ${message.data}');
        
        RemoteNotification? notification = message.notification;
        String title = notification?.title ?? message.data['title'] ?? '🚨 Notice Alert';
        String body = notification?.body ?? message.data['body'] ?? message.data['content'] ?? 'New notification received';

        _localNotifications.show(
          message.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      });

      // 5. Handle Notification Opened App
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM LOG] Notification opened app: ${message.data}');
      });

      // 6. Subscribe to notice_all asynchronously without blocking App UI launch
      _messaging.subscribeToTopic('notice_all').then((_) {
        debugPrint("[FCM LOG] Subscribed to topic: notice_all on background thread!");
      }).catchError((e) {
        debugPrint("[FCM LOG] Error subscribing to notice_all: $e");
      });
    } catch (e, stack) {
      debugPrint('[FCM LOG] NotificationService initialize error: $e');
      debugPrint('[FCM LOG] Stacktrace: $stack');
    }
  }

  /// Subscribe User to FCM Topics and Send Token to Backend
  static Future<void> setupUserNotifications(String role, {String? token}) async {
    debugPrint("[FCM LOG] Setting up user notifications for role: $role");

    // 1. Get and send FCM token first
    try {
      String? fcmToken = token ?? await _messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint("[FCM LOG] FCM Token successfully obtained: $fcmToken");
        await _sendTokenToBackend(fcmToken);
      } else {
        debugPrint("[FCM LOG] WARNING: _messaging.getToken() returned NULL or empty string!");
      }
    } catch (e, stack) {
      debugPrint("[FCM LOG] Error getting or sending FCM token: $e");
      debugPrint("[FCM LOG] Stacktrace: $stack");
    }

    // 2. Role specific topic subscription
    try {
      await _messaging.subscribeToTopic('notice_all');
      debugPrint("[FCM LOG] Subscribed to topic: notice_all");

      final lowerRole = role.toLowerCase();
      if (lowerRole == 'teacher') {
        await _messaging.subscribeToTopic('notice_teachers');
        await _messaging.unsubscribeFromTopic('notice_students');
        debugPrint("[FCM LOG] Subscribed to topic: notice_teachers");
      } else if (lowerRole == 'student') {
        await _messaging.subscribeToTopic('notice_students');
        await _messaging.unsubscribeFromTopic('notice_teachers');
        debugPrint("[FCM LOG] Subscribed to topic: notice_students");
      }
    } catch (e) {
      debugPrint("[FCM LOG] Error subscribing to topics: $e");
    }

    // 3. Listen for Token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint("[FCM LOG] FCM Token refreshed: $newToken");
      _sendTokenToBackend(newToken);
    });
  }

  /// Send FCM Token to Laravel Backend (/api/user/fcm-token)
  static Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      debugPrint("[FCM LOG] Sending FCM Token to Laravel backend...");
      final res = await ApiServices.updateFcmToken(fcmToken);
      debugPrint("[FCM LOG] Backend response: $res");
    } catch (e) {
      debugPrint("[FCM LOG] Failed to send FCM token to backend: $e");
    }
  }
}
