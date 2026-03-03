import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel values mirrored from the native Android reference:
/// - channel_id: hardik-channel
/// - channel_name: hardik
const String kAndroidChannelId = 'hardik-channel';
const String kAndroidChannelName = 'hardik';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// A low-importance notification channel to match the native Kotlin implementation
/// (IMPORTANCE_LOW with vibration and green lights).
const AndroidNotificationChannel _androidNotificationChannel =
    AndroidNotificationChannel(
  kAndroidChannelId,
  kAndroidChannelName,
  description: 'FCM notifications (mirrors native Android channel behavior)',
  importance: Importance.low,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF00FF00), // green
);

/// PUBLIC_INTERFACE
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  """Background/terminated FCM handler.

  This runs in a separate isolate. It initializes Firebase and shows a local
  notification for both notification-payload and data-only messages, mirroring
  the native Android service behavior.
  """;
  await Firebase.initializeApp();
  await _ensureLocalNotificationsInitialized();

  final (title, body) = _extractTitleBody(message);
  await _showLocalNotification(title: title, body: body, data: message.data);
}

/// PUBLIC_INTERFACE
Future<void> main() async {
  """App entry point.

  Initializes Firebase + FCM handlers and sets up Android notification channel
  and local notifications, then runs the Flutter app.
  """;
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await _ensureLocalNotificationsInitialized();
  await _configureFcm();

  runApp(const MyApp());
}

Future<void> _ensureLocalNotificationsInitialized() async {
  // Initialize the plugin (required on Android before showing notifications).
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await _localNotifications.initialize(initSettings);

  // Create/update notification channel on Android (O+).
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(_androidNotificationChannel);
  }
}

Future<void> _configureFcm() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Android 13+ and iOS require runtime permission for notifications.
  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
  );

  if (kDebugMode) {
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  // Token retrieval (native reference logs token onNewToken()).
  final String? token = await messaging.getToken();
  if (kDebugMode) {
    debugPrint('FCM token --> $token');
  }

  // Token refresh handling
  messaging.onTokenRefresh.listen((String newToken) {
    if (kDebugMode) {
      debugPrint('FCM token refreshed --> $newToken');
    }
  });

  // Foreground message handling:
  // - If message.notification exists -> use it
  // - Else fall back to data payload keys (title/message)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final (title, body) = _extractTitleBody(message);
    await _showLocalNotification(
      title: title,
      body: body,
      data: message.data,
    );
  });

  // User tapped notification while app in background.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification opened app with data: ${message.data}');
    }
  });

  // If the app was launched by tapping a notification while terminated.
  final RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null && kDebugMode) {
    debugPrint('App launched from terminated by notification: '
        '${initialMessage.data}');
  }
}

(String? title, String? body) _extractTitleBody(RemoteMessage message) {
  // Mirror native Kotlin behavior:
  // if (remoteMessage.notification != null) showNotification(notification.title, notification.body)
  // else showNotification(data["title"], data["message"])
  final RemoteNotification? notif = message.notification;
  if (notif != null) {
    return (notif.title, notif.body);
  }
  return (message.data['title'] as String?, message.data['message'] as String?);
}

Future<void> _showLocalNotification({
  required String? title,
  required String? body,
  required Map<String, dynamic> data,
}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    _androidNotificationChannel.id,
    _androidNotificationChannel.name,
    channelDescription: _androidNotificationChannel.description,
    importance: Importance.low,
    priority: Priority.low,
    enableVibration: true,
    enableLights: true,
    ledColor: const Color(0xFF00FF00),
    icon: '@mipmap/ic_launcher',
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await _localNotifications.show(
    notificationId,
    title ?? 'Notification',
    body ?? '',
    platformDetails,
    payload: data.isEmpty ? null : data.toString(),
  );
}

/// Minimal app UI kept to satisfy existing test expectations.
class MyApp extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sample_notifications_frontend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sample_notifications_frontend'),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('sample_notifications_frontend App is being generated...'),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
