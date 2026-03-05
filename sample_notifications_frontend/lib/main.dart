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

  Preview environments (and some emulators) can behave poorly if we await
  Firebase init or show permission prompts *before the first Flutter frame*.
  If an exception occurs during those awaits, the app may appear as a white
  screen with no visible error.

  Strategy:
  - Render UI immediately via `runApp()`.
  - Perform Firebase + notification initialization post-frame from the UI,
    and show a visible error state if anything fails.
  """;
  WidgetsFlutterBinding.ensureInitialized();

  // Log framework and platform errors so a failure doesn't manifest as a silent
  // white screen in preview environments.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('${details.stack}');
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Uncaught platform error: $error');
      debugPrint('$stack');
    }
    return false; // allow default handling too
  };

  // Never block first frame on async init.
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

  // Token retrieval can throw/hang in some preview/emulator setups (esp. when
  // Google Play services are not fully available). Do not allow it to blank UI.
  try {
    final String? token =
        await messaging.getToken().timeout(const Duration(seconds: 6));
    if (kDebugMode) {
      debugPrint('FCM token --> $token');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('FCM token retrieval failed (non-fatal): $e');
    }
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
  try {
    final RemoteMessage? initialMessage =
        await messaging.getInitialMessage().timeout(const Duration(seconds: 4));
    if (initialMessage != null && kDebugMode) {
      debugPrint('App launched from terminated by notification: '
          '${initialMessage.data}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('getInitialMessage failed (non-fatal): $e');
    }
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

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  bool _initStarted = false;

  /// Whether initialization completed successfully.
  bool _initOk = false;

  /// Whether initialization failed (we show a visible error instead of a blank UI).
  bool _initFailed = false;

  String? _initErrorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure we only kick off initialization once.
    if (_initStarted) return;
    _initStarted = true;

    // Post-frame: avoids permission prompts / heavy init during cold-start before the
    // first Flutter frame, which can cause a white screen in some preview envs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitPipeline();
    });
  }

  Future<void> _startInitPipeline() async {
    try {
      // In preview environments, permission prompts + plugin init can hang or throw
      // (e.g., missing Google Play services, transient binder issues).
      // Use timeouts so the UI never gets stuck on an indefinite spinner/blank.
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));

      // Register background handler only after Firebase is available.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _ensureLocalNotificationsInitialized()
          .timeout(const Duration(seconds: 10));

      // Important: requesting permissions can trigger OS UI and is the common repro
      // point. Bound it with a timeout and treat failures as non-fatal to rendering.
      await _configureFcm().timeout(const Duration(seconds: 12));

      if (!mounted) return;
      setState(() {
        _initOk = true;
        _initFailed = false;
        _initErrorMessage = null;
      });
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('Post-frame init timed out: $e');
      }
      if (!mounted) return;
      setState(() {
        _initOk = false;
        _initFailed = true;
        _initErrorMessage =
            'Initialization timed out (preview/device permission UI may have stalled).';
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Post-frame init failed: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      setState(() {
        _initOk = false;
        _initFailed = true;
        _initErrorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget statusWidget;
    if (_initFailed) {
      statusWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Initialization failed.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _initErrorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (_initOk) {
      statusWidget = const Text(
        'App is ready. Send an FCM push to see a notification.',
        textAlign: TextAlign.center,
      );
    } else {
      statusWidget = const CircularProgressIndicator();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('sample_notifications_frontend'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'sample_notifications_frontend',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              statusWidget,
            ],
          ),
        ),
      ),
    );
  }
}
