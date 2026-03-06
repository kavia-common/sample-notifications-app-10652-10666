import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'ecommerce/state/app_state_providers.dart';
import 'notifications/notification_service.dart';
import 'notifications/push_manager.dart';
import 'routing/app_router.dart';
import 'routing/deep_link_coordinator.dart';

/// PUBLIC_INTERFACE
Future<void> main() async {
  """App entry point.

  Initializes Firebase + notifications after Flutter binding is ready, then
  starts:
  - FCM handlers (PushManager)
  - Local notifications (NotificationService)
  - Deep link listeners (uni_links + notification actions) via DeepLinkCoordinator

  Navigation uses go_router and deep links are accepted as:
  - myapp://orders
  - myapp://chat?threadId=42
  """;
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('${details.stack}');
    }
  };

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initStarted = false;
  DeepLinkCoordinator? _coordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initStarted) return;
    _initStarted = true;

    // Post-frame so we don't delay first paint with permission dialogs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInit();
    });
  }

  Future<void> _startInit() async {
    try {
      await NotificationService.instance.initialize().timeout(const Duration(seconds: 10));
      await PushManager.instance.initialize().timeout(const Duration(seconds: 12));

      // Coordinator drives navigation without needing BuildContext.
      final DeepLinkCoordinator coordinator = DeepLinkCoordinator(
        router: AppRouter.router,
        notificationService: NotificationService.instance,
      );
      _coordinator = coordinator;
      await coordinator.start().timeout(const Duration(seconds: 8));
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('Init timed out (non-fatal): $e');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Init failed (non-fatal): $e');
        debugPrint('$st');
      }
    }
  }

  @override
  void dispose() {
    // Best-effort cleanup (not strictly necessary for app lifetime).
    unawaited(_coordinator?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppStateProviders.build(),
      child: MaterialApp.router(
        title: 'sample_notifications_frontend',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
