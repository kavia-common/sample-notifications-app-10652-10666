import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ecommerce/models/order.dart';
import '../ecommerce/state/orders_state.dart';
import '../ecommerce/utils/money.dart';

class OrdersScreen extends StatefulWidget {
  /// PUBLIC_INTERFACE
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Prevent re-entrant navigation when both PopScope and AppBar back (or rapid
  // repeated back presses) try to trigger navigation.
  bool _isExiting = false;

  void _exitToHome(BuildContext context) {
    // IMPORTANT:
    // For go_router apps, using Navigator.canPop/maybePop here can be misleading
    // because go_router manages a separate route stack. In some deep-link
    // scenarios, that can create a loop where "back" never resolves.
    //
    // Requirement: Back from Orders should always land on Home.
    if (_isExiting) return;
    _isExiting = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = context.watch<OrdersState>().orders;

    return PopScope(
      // We fully handle "back" ourselves to avoid inconsistent behavior between
      // the system back gesture and the AppBar leading button.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _exitToHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _exitToHome(context),
          ),
          title: const Text('Orders'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Shop',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.storefront_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.receipt_long_outlined, size: 56),
                        const SizedBox(height: 12),
                        const Text(
                          'No orders yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Place an order from Checkout.\n(deep link: myapp://orders)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Start shopping'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Order o = orders[index];
                    final String total = Money.formatCents(
                      cents: o.totalCents,
                      currencyCode: o.currencyCode,
                    );

                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      title: Text(
                        'Order ${o.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${o.items.length} items • ${o.status.name.toUpperCase()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                        ),
                      ),
                      trailing: Text(
                        total,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onTap: () => context.go('/orders/${o.id}'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
