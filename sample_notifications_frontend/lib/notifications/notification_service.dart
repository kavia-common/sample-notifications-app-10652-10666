import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deep_link_parser.dart';

/// Notification category (iOS) / semantic group used by this demo.
const String kNotificationCategoryGeneral = 'general';

/// Action IDs used in callbacks. These do not need to match button titles.
/// Keep them stable for Android PendingIntent uniqueness and iOS categories.
const String kActionOpenChat = 'OPEN_CHAT';
const String kActionOpenOrders = 'OPEN_ORDERS';

/// Payload envelope keys for action routing.
const String _kPayloadDefaultDeepLink = 'defaultDeepLink';
const String _kPayloadActionMap = 'actionMap';

/// Background callback for notification taps/actions.
///
/// flutter_local_notifications requires the background handler to be a top-level
/// or static function, and it must be marked as an entry-point so it is not
/// tree-shaken in release builds.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.instance.handleNotificationResponse(response);
}

/// Small helper DTO for an emitted deep-link event.
class DeepLinkEvent {
  const DeepLinkEvent({
    required this.rawDeepLink,
    required this.source,
  });

  /// The deep link in its original form (e.g. "myapp://orders").
  final String rawDeepLink;

  /// Debug info: "notification_tap", "notification_action:OPEN_CHAT", "uni_links", etc.
  final String source;

  /// Converts to a go_router location like "/orders" or "/chat?threadId=42".
  String? get routerLocation => DeepLinkParser.toRouterLocation(rawDeepLink);
}

/// Local notifications + action handling.
/// Owns the flutter_local_notifications plugin initialization and exposes a stream
/// of deep-links that the app should navigate to.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final StreamController<DeepLinkEvent> _deepLinkEvents =
      StreamController<DeepLinkEvent>.broadcast();

  /// Events can occur *before* the app has attached a listener (e.g. cold start
  /// from notification tap). Buffer them and let the router coordinator drain.
  final List<DeepLinkEvent> _pendingEvents = <DeepLinkEvent>[];

  /// PUBLIC_INTERFACE
  /// Stream of deep-link events emitted by notification taps or action button taps.
  Stream<DeepLinkEvent> get deepLinkEvents => _deepLinkEvents.stream;

  /// PUBLIC_INTERFACE
  /// Returns and clears any buffered deep-link events that arrived before a
  /// listener was attached (typical for cold start / early init).
  List<DeepLinkEvent> drainPendingEvents() {
    final List<DeepLinkEvent> out = List<DeepLinkEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    return out;
  }

  /// PUBLIC_INTERFACE
  /// Initializes notification channels (Android) and categories/actions (iOS),
  /// and wires callbacks to emit deep-link events.
  Future<void> initialize() async {
    if (_initialized) return;

    final AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: categories with actions (2 buttons).
    //
    // NOTE: We intentionally avoid `const` here because the `flutter_local_notifications`
    // plugin has had constructor const-ness differences across versions.
    final DarwinNotificationCategory generalCategory = DarwinNotificationCategory(
      kNotificationCategoryGeneral,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          kActionOpenChat,
          'Open Chat',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          kActionOpenOrders,
          'Open Orders',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        // This makes actions available on iOS lock screen/notification center.
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    );

    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      notificationCategories: <DarwinNotificationCategory>[generalCategory],
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android channel (O+). Must match the manifest default channel id.
    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlatform != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'hardik-channel',
        'hardik',
        description: 'FCM notifications with actions (demo)',
        importance: Importance.low,
      );
      await androidPlatform.createNotificationChannel(channel);

      // Android 13+ requires POST_NOTIFICATIONS permission for local notifications.
      // (On older Android versions this is a no-op.)
      try {
        await androidPlatform.requestNotificationsPermission();
      } catch (_) {
        // Non-fatal: some platform builds may not support the call.
      }
    }

    // Permissions (local notifications). FCM permission is requested elsewhere.
    final IOSFlutterLocalNotificationsPlugin? iosPlatform =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlatform?.requestPermissions(alert: true, badge: true, sound: true);

    final MacOSFlutterLocalNotificationsPlugin? macPlatform =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macPlatform?.requestPermissions(alert: true, badge: true, sound: true);

    // Cold-start from a notification tap: capture and emit/buffer it.
    try {
      final NotificationAppLaunchDetails? details = await _plugin.getNotificationAppLaunchDetails();
      final NotificationResponse? response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        handleNotificationResponse(response);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getNotificationAppLaunchDetails failed (non-fatal): $e');
      }
    }

    _initialized = true;
  }

  /// PUBLIC_INTERFACE
  /// Builds and shows a local notification from an FCM-like data payload.
  ///
  /// Expected keys:
  /// - title, body
  /// - defaultDeepLink
  /// - actionTitles: comma-separated (optional)
  /// - actionDeepLinks: comma-separated (optional, must align with titles)
  ///
  /// Example:
  /// {
  ///  "title": "New message",
  ///  "body": "You have a new chat message",
  ///  "defaultDeepLink": "myapp://chat?threadId=42",
  ///  "actionTitles": "Open Chat,Open Orders",
  ///  "actionDeepLinks": "myapp://chat?threadId=42,myapp://orders",
  ///  "notificationId": "9876",
  ///  "category": "chat"
  /// }
  Future<void> showNotificationFromData(Map<String, dynamic> data) async {
    await initialize();

    final String title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? (data['title'] as String).trim()
        : 'Notification';
    final String body = (data['body'] as String?)?.trim() ?? '';

    final String? defaultDeepLink = (data['defaultDeepLink'] as String?)?.trim();
    final int id = int.tryParse((data['notificationId'] as String?) ?? '') ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final List<_ActionSpec> actions = _extractActionSpecs(data);

    final Map<String, String> actionMap = <String, String>{};
    for (final _ActionSpec spec in actions) {
      actionMap[spec.actionId] = spec.deepLink;
    }

    final String payload = jsonEncode(<String, dynamic>{
      _kPayloadDefaultDeepLink: defaultDeepLink,
      _kPayloadActionMap: actionMap,
    });

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hardik-channel',
      'hardik',
      channelDescription: 'FCM notifications with actions (demo)',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      actions: actions
          .map(
            (_ActionSpec a) => AndroidNotificationAction(
              a.actionId,
              a.title,
              // Ensures the app UI is brought forward on action tap.
              showsUserInterface: true,
              // Important: make each action intent unique.
              // The plugin internally handles uniqueness but stable IDs help.
              // (Acceptance criteria mentions unique PendingIntents.)
              cancelNotification: true,
            ),
          )
          .toList(),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: kNotificationCategoryGeneral,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// PUBLIC_INTERFACE
  /// Handles notification tap/action callbacks from flutter_local_notifications.
  ///
  /// This must be safe to call from:
  /// - foreground isolate (normal app runtime)
  /// - background callback entry-point (Android)
  ///
  /// It emits (or buffers) a DeepLinkEvent that DeepLinkCoordinator will turn into
  /// go_router navigation.
  void handleNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification payload decode failed: $e');
      }
      return;
    }

    final String? defaultDeepLink = (decoded[_kPayloadDefaultDeepLink] as String?)?.trim();
    final Map<String, dynamic> actionMap =
        (decoded[_kPayloadActionMap] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final String actionId = response.actionId ?? '';
    String? chosen;
    String source;

    // Version-compatible default tap detection:
    // - Some plugin versions do NOT expose NotificationResponse.defaultActionId.
    // - `notificationResponseType` is the safest way to distinguish main tap vs action tap.
    final bool isDefaultTap =
        response.notificationResponseType == NotificationResponseType.selectedNotification;

    if (isDefaultTap || actionId.isEmpty) {
      chosen = defaultDeepLink;
      source = 'notification_tap';
    } else {
      final String? mapped = actionMap[actionId] as String?;
      chosen = mapped?.trim();
      source = 'notification_action:$actionId';

      // Fallback: if action link missing, fall back to defaultDeepLink (if present).
      if (chosen == null || chosen.isEmpty) {
        chosen = defaultDeepLink?.trim();
        source = 'notification_action_fallback';
      }
    }

    if (chosen == null || chosen.trim().isEmpty) return;

    final DeepLinkEvent event = DeepLinkEvent(rawDeepLink: chosen.trim(), source: source);

    // If the coordinator isn't yet listening (common on cold start), buffer the
    // event so the coordinator can drain it after it attaches.
    if (!_deepLinkEvents.hasListener) {
      _pendingEvents.add(event);
      return;
    }

    _deepLinkEvents.add(event);
  }

  List<_ActionSpec> _extractActionSpecs(Map<String, dynamic> data) {
    final String titlesRaw = (data['actionTitles'] as String?) ?? '';
    final String linksRaw = (data['actionDeepLinks'] as String?) ?? '';

    final List<String> titles = titlesRaw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    final List<String> links = linksRaw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();

    if (titles.isEmpty || links.isEmpty) return <_ActionSpec>[];

    final int count = titles.length < links.length ? titles.length : links.length;

    // Map the first two actions to stable IDs for the demo.
    // If more actions are provided, create deterministic IDs.
    final List<_ActionSpec> out = <_ActionSpec>[];
    for (int i = 0; i < count; i++) {
      final String title = titles[i];
      final String deepLink = links[i];

      String actionId;
      if (i == 0) {
        actionId = kActionOpenChat;
      } else if (i == 1) {
        actionId = kActionOpenOrders;
      } else {
        actionId = 'ACTION_$i';
      }

      out.add(_ActionSpec(actionId: actionId, title: title, deepLink: deepLink));
    }
    return out;
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.actionId,
    required this.title,
    required this.deepLink,
  });

  final String actionId;
  final String title;
  final String deepLink;
}
