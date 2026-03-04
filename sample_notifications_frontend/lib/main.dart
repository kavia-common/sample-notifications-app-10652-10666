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
  // Initialize the plugin (required before showing notifications).
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // For iOS local notifications:
  // - We'll request permissions explicitly via the plugin (below).
  // - defaultPresent* ensures foreground notifications can show while app is open.
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    defaultPresentAlert: true,
    defaultPresentBadge: true,
    defaultPresentSound: true,
  );

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

  // iOS permission prompt (local notifications). This does NOT require APNs or
  // an Apple Developer account.
  final IOSFlutterLocalNotificationsPlugin? iosPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
  await iosPlugin?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

  final MacOSFlutterLocalNotificationsPlugin? macPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
  await macPlugin?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _configureFcm() async {
  // Local-notifications-only POC:
  // Keep FCM wiring in place for Android / future expansion, but do not rely on
  // iOS APNs/FCM capabilities for this POC.
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Android 13+ requires runtime permission; iOS permission is handled above via
  // flutter_local_notifications for this local-only POC.
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

  // Token retrieval (primarily relevant on Android; iOS requires APNs setup).
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
