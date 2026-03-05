import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../notifications/notification_service.dart';

/// Coordinates navigation requests coming from:
/// - Notification taps / action buttons (NotificationService.deepLinkEvents)
/// - External deep links (AppLinks initial link + URI stream)
class DeepLinkCoordinator {
  DeepLinkCoordinator({
    required GoRouter router,
    required NotificationService notificationService,
  })  : _router = router,
        _notificationService = notificationService;

  final GoRouter _router;
  final NotificationService _notificationService;

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<DeepLinkEvent>? _notificationSub;
  StreamSubscription<Uri>? _uriStreamSub;

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
      final Uri? initial = await _appLinks.getInitialLink();
      final String? initialStr = initial?.toString().trim();
      if (initialStr != null && initialStr.isNotEmpty) {
        final DeepLinkEvent event = DeepLinkEvent(rawDeepLink: initialStr, source: 'app_links_initial');
        final String? location = event.routerLocation;
        if (location != null) {
          _router.go(location);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('app_links getInitialLink failed (non-fatal): $e');
      }
    }

    // Warm start deep links.
    _uriStreamSub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final String link = uri.toString().trim();
        if (link.isEmpty) return;

        final DeepLinkEvent event = DeepLinkEvent(rawDeepLink: link, source: 'app_links_stream');
        final String? location = event.routerLocation;
        if (location != null) {
          _router.go(location);
        }
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('app_links uriLinkStream error (non-fatal): $e');
        }
      },
    );
  }

  /// PUBLIC_INTERFACE
  /// Stops subscriptions (typically not needed for app lifetime).
  Future<void> dispose() async {
    await _notificationSub?.cancel();
    await _uriStreamSub?.cancel();
  }
}
