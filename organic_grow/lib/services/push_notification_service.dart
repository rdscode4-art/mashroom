import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print("Notification tapped: ${response.payload}");
      },
    );

    // Create default channel
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          'default_channel',
          'General Notifications',
          description: 'General app updates',
          importance: Importance.high,
          playSound: true,
        );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(defaultChannel);

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Get FCM token and send to backend
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
      await sendTokenToBackend(token);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      AndroidNotificationDetails androidDetails =
          const AndroidNotificationDetails(
            'default_channel',
            'General Notifications',
            channelDescription: 'General app updates',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token'); // Auth token

      if (userToken != null) {
        final dio = Dio();
        await dio.put(
          'https://mushroomback.ridealdigitalseva.com/api/auth/fcm-token',
          data: {'fcmToken': token},
          options: Options(headers: {'Authorization': 'Bearer $userToken'}),
        );
        print("FCM Token sent to backend successfully.");
      }
    } catch (e) {
      print("Error sending FCM token to backend: $e");
    }
  }

  static Future<void> syncToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await sendTokenToBackend(token);
    }
  }
}
