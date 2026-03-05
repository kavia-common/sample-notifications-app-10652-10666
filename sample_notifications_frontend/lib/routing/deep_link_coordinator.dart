import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_links/uni_links.dart';

import '../notifications/notification_service.dart';

/// Coordinates navigation requests coming from:
/// - Notification taps / action buttons (NotificationService.deepLinkEvents)
/// - External deep links (uni_links initial link + link stream)
class DeepLinkCoordinator {
  DeepLinkCoordinator({
    required GoRouter router,
    required NotificationService notificationService,
  })  : _router = router,
        _notificationService = notificationService;

  final GoRouter _router;
  final NotificationService _notificationService;

  StreamSubscription<DeepLinkEvent>? _notificationSub;
  StreamSubscription<String?>? _linkStreamSub;

  bool _started = false;

  /// PUBLIC_INTERFACE
  /// Starts listening for deep-link events and navigates via go_router.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _notificationSub = _notificationService.deepLinkEvents.listen((DeepLinkEvent event) {
      final String? location = event.routerLocation;
      if (location == null) return;

      if (kDebugMode) {
        debugPrint('DeepLinkCoordinator: navigating to $location from ${event.source}');
      }

      // No async gap here, safe to call router.go.
      _router.go(location);
    });

    // Cold start deep link (terminated -> opened via URL).
    try {
      final String? initial = await getInitialLink();
      if (initial != null && initial.trim().isNotEmpty) {
        final DeepLinkEvent event = DeepLinkEvent(rawDeepLink: initial.trim(), source: 'uni_links_initial');
        final String? location = event.routerLocation;
        if (location != null) {
          _router.go(location);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('uni_links getInitialLink failed (non-fatal): $e');
      }
    }

    // Warm start deep links.
    _linkStreamSub = linkStream.listen(
      (String? link) {
        if (link == null || link.trim().isEmpty) return;
        final DeepLinkEvent event = DeepLinkEvent(rawDeepLink: link.trim(), source: 'uni_links_stream');
        final String? location = event.routerLocation;
        if (location != null) {
          _router.go(location);
        }
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('uni_links linkStream error (non-fatal): $e');
        }
      },
    );
  }

  /// PUBLIC_INTERFACE
  /// Stops subscriptions (typically not needed for app lifetime).
  Future<void> dispose() async {
    await _notificationSub?.cancel();
    await _linkStreamSub?.cancel();
  }
}
