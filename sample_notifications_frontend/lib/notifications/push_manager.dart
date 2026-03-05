import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Handles Firebase Cloud Messaging setup and ensures we display actionable local
/// notifications for foreground messages and data-only pushes.
///
/// Also handles background isolate entry-point for onBackgroundMessage.
class PushManager {
  PushManager._();

  static final PushManager instance = PushManager._();

  bool _initialized = false;

  /// PUBLIC_INTERFACE
  /// Background handler: must be a top-level or static entry point.
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();

    // Ensure notification plugin is ready in the background isolate too.
    await NotificationService.instance.initialize();

    // Always render a local notification from message.data when in background.
    // For notification payloads, message.notification might exist, but data is
    // required for actionable deep-link routing.
    final Map<String, dynamic> data = <String, dynamic>{
      ...message.data,
    };

    // If title/body are not present in data, copy from notification payload.
    if (data['title'] == null && message.notification?.title != null) {
      data['title'] = message.notification!.title;
    }
    if (data['body'] == null && message.notification?.body != null) {
      data['body'] = message.notification!.body;
    }

    await NotificationService.instance.showNotificationFromData(data);
  }

  /// PUBLIC_INTERFACE
  /// Initializes FCM permissions + handlers.
  ///
  /// Note: navigation is not done here; NotificationService emits deep-link events
  /// that the DeepLinkCoordinator consumes.
  Future<void> initialize() async {
    if (_initialized) return;

    await NotificationService.instance.initialize();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Permissions: Android 13+ and iOS.
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

    // Foreground -> show a local notification with actions (so user can act).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final Map<String, dynamic> data = <String, dynamic>{
        ...message.data,
      };

      if (data['title'] == null && message.notification?.title != null) {
        data['title'] = message.notification!.title;
      }
      if (data['body'] == null && message.notification?.body != null) {
        data['body'] = message.notification!.body;
      }

      await NotificationService.instance.showNotificationFromData(data);
    });

    // Background -> user tapped notification (default tap). Plugin callback will
    // emit deep-link event via NotificationService. This listener is still useful
    // for debugging/logging.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('onMessageOpenedApp: ${message.data}');
      }
    });

    _initialized = true;
  }

  /// PUBLIC_INTERFACE
  /// Returns the initial RemoteMessage (if the app was launched by tapping an FCM
  /// notification while terminated).
  ///
  /// This is a best-effort helper; deep-link navigation is primarily handled via
  /// flutter_local_notifications callbacks + uni_links initial link.
  Future<RemoteMessage?> getInitialFcmMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }
  }

  /// PUBLIC_INTERFACE
  /// Retrieves the current FCM token (may be null on environments without Play Services).
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 6));
    } catch (_) {
      return null;
    }
  }
}
