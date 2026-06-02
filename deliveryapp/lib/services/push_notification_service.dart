import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../core/controllers/delivery_controller.dart';

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
      criticalAlert: true,
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

    // Create custom channel for orders
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'order_channel', // id
      'New Orders', // name
      description: 'Notifications for new pickup requests',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('order_sound'),
      playSound: true,
      enableVibration: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(orderChannel);

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        bool isOrder = message.data['type'] == 'new_order';
        if (!isOrder) {
          _showLocalNotification(message);
        } else {
          print(
            'Skipping local notification for new_order because app is in foreground. main.dart will handle overlay.',
          );
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped from background!');
      cancelAllNotifications();
      // Wait a moment for GetX to be ready before calling the controller
      Future.delayed(const Duration(milliseconds: 200), () {
        if (Get.isRegistered<DeliveryController>()) {
          Get.find<DeliveryController>().fetchAssignedOrder();
        }
      });
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

  static Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Check if it's an order notification (based on channel setup in backend)
      bool isOrder = message.data['type'] == 'new_order';

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        isOrder ? 'order_channel' : 'default_channel',
        isOrder ? 'New Orders' : 'General Notifications',
        channelDescription: isOrder
            ? 'New pickup requests'
            : 'General app updates',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: isOrder
            ? const RawResourceAndroidNotificationSound('order_sound')
            : null,
        fullScreenIntent: isOrder, // Wakes up screen
      );

      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: isOrder ? 'order_sound.aiff' : null,
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
      final userToken = prefs.getString('delivery_token'); // Auth token

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
