import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ecommerce/models/order.dart';
import '../ecommerce/state/cart_state.dart';
import '../ecommerce/state/orders_state.dart';
import '../ecommerce/utils/money.dart';
import '../notifications/notification_service.dart';

class CheckoutScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placeOrderRequested = false;
  String? _snackMessage;

  void _requestPlaceOrder() {
    setState(() {
      _placeOrderRequested = true;
    });
  }

  Future<void> _doPlaceOrder({
    required CartState cart,
    required OrdersState orders,
  }) async {
    // Place order synchronously (state change).
    final Order order = orders.placeOrder(
      cartItems: cart.snapshotItems(),
      subtotalCents: cart.subtotalCents,
      shippingCents: cart.shippingCents,
      taxCents: cart.taxCents,
      totalCents: cart.totalCents,
      currencyCode: cart.currencyCode,
    );

    cart.clear();

    // Trigger local notification that deep-links into orders.
    // No UI calls after await (we only set primitive state after await).
    await NotificationService.instance.showNotificationFromData(<String, dynamic>{
      'title': 'Order placed',
      'body': 'Your order ${order.id} was placed successfully.',
      'defaultDeepLink': 'myapp://orders',
      'actionTitles': 'Open Orders',
      'actionDeepLinks': 'myapp://orders',

      // Use both a unique notificationId + a unique Android tag to ensure repeated
      // order notifications never overwrite each other.
      'notificationId': DateTime.now().millisecondsSinceEpoch.toString(),
      'notificationTag': 'order:${order.id}',

      'category': 'orders',
    });

    if (!mounted) return;
    setState(() {
      _snackMessage = 'Order placed: ${order.id}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final CartState cart = context.watch<CartState>();
    final OrdersState orders = context.read<OrdersState>();

    // Navigation/snackbar from build only, driven by primitive flags.
    if (_placeOrderRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Prevent multiple triggers.
        if (!mounted) return;
        setState(() {
          _placeOrderRequested = false;
        });

        // If cart empty, just message and go back.
        if (cart.items.isEmpty) {
          if (!mounted) return;
          setState(() {
            _snackMessage = 'Cart is empty';
          });
          return;
        }

        await _doPlaceOrder(cart: cart, orders: orders);

        if (!mounted) return;
        context.go('/orders');
      });
    }

    final String? snackMessage = _snackMessage;
    if (snackMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snackMessage)));
        if (mounted) {
          setState(() {
            _snackMessage = null;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SafeArea(
        child: cart.items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.payments_outlined, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'Nothing to pay',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your cart is empty.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Back to shop'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    'Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text(
                            'Demo payment method',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This is a demo checkout (no real payment processing).',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Row(
                            label: 'Subtotal',
                            value: Money.formatCents(
                              cents: cart.subtotalCents,
                              currencyCode: cart.currencyCode,
                            ),
                          ),
                          _Row(
                            label: 'Shipping',
                            value: Money.formatCents(
                              cents: cart.shippingCents,
                              currencyCode: cart.currencyCode,
                            ),
                          ),
                          _Row(
                            label: 'Tax',
                            value: Money.formatCents(
                              cents: cart.taxCents,
                              currencyCode: cart.currencyCode,
                            ),
                          ),
                          const Divider(height: 24),
                          _Row(
                            label: 'Total',
                            value: Money.formatCents(
                              cents: cart.totalCents,
                              currencyCode: cart.currencyCode,
                            ),
                            isEmphasis: true,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _requestPlaceOrder,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Place order'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isEmphasis = false});

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = isEmphasis
        ? const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)
        : TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(200));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
