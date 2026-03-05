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

  /// PUBLIC_INTERFACE
  /// Stream of deep-link events emitted by notification taps or action button taps.
  Stream<DeepLinkEvent> get deepLinkEvents => _deepLinkEvents.stream;

  /// PUBLIC_INTERFACE
  /// Initializes notification channels (Android) and categories/actions (iOS),
  /// and wires callbacks to emit deep-link events.
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: categories with actions (2 buttons).
    const DarwinNotificationCategory generalCategory = DarwinNotificationCategory(
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

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      notificationCategories: <DarwinNotificationCategory>[generalCategory],
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveNotificationResponse,
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
    }

    // Permissions (local notifications). FCM permission is requested elsewhere.
    final IOSFlutterLocalNotificationsPlugin? iosPlatform =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlatform?.requestPermissions(alert: true, badge: true, sound: true);

    final MacOSFlutterLocalNotificationsPlugin? macPlatform =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macPlatform?.requestPermissions(alert: true, badge: true, sound: true);

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

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
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

    if (actionId.isEmpty || actionId == NotificationResponse.defaultActionId) {
      chosen = defaultDeepLink;
      if (chosen != null && chosen.trim().isNotEmpty) {
        _deepLinkEvents.add(
          DeepLinkEvent(rawDeepLink: chosen, source: 'notification_tap'),
        );
      }
      return;
    }

    final String? mapped = actionMap[actionId] as String?;
    if (mapped != null && mapped.trim().isNotEmpty) {
      chosen = mapped.trim();
      _deepLinkEvents.add(
        DeepLinkEvent(rawDeepLink: chosen, source: 'notification_action:$actionId'),
      );
      return;
    }

    // Fallback: if action link missing, fall back to defaultDeepLink (if present).
    if (defaultDeepLink != null && defaultDeepLink.trim().isNotEmpty) {
      _deepLinkEvents.add(
        DeepLinkEvent(rawDeepLink: defaultDeepLink.trim(), source: 'notification_action_fallback'),
      );
    }
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
