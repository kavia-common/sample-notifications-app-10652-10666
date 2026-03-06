import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/cart_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/home_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/token_screen.dart';

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

      // E-commerce flow.
      GoRoute(
        path: '/cart',
        builder: (BuildContext context, GoRouterState state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (BuildContext context, GoRouterState state) => const CheckoutScreen(),
      ),

      // Keep a separate token screen (as requested) so the user can copy the FCM token.
      GoRoute(
        path: '/token',
        builder: (BuildContext context, GoRouterState state) => const TokenScreen(),
      ),

      // Orders (deep link: myapp://orders). Kept stable.
      GoRoute(
        path: '/orders',
        builder: (BuildContext context, GoRouterState state) => const OrdersScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':orderId',
            builder: (BuildContext context, GoRouterState state) {
              final String orderId = state.pathParameters['orderId'] ?? '';
              return OrderDetailScreen(orderId: orderId);
            },
          ),
        ],
      ),

      // Existing chat route preserved (deep link: myapp://chat?threadId=42).
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
