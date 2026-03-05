import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/chat_screen.dart';
import '../screens/home_screen.dart';
import '../screens/orders_screen.dart';

class AppRouter {
  AppRouter._();

  /// PUBLIC_INTERFACE
  /// Global GoRouter instance used by the app.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (BuildContext context, GoRouterState state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (BuildContext context, GoRouterState state) {
          final String? threadId = state.uri.queryParameters['threadId'];
          return ChatScreen(threadId: threadId);
        },
      ),
    ],
  );
}
