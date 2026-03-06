import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ecommerce/models/cart_item.dart';
import '../ecommerce/models/order.dart';
import '../ecommerce/state/orders_state.dart';
import '../ecommerce/utils/money.dart';

class OrderDetailScreen extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final List<Order> orders = context.watch<OrdersState>().orders;
    final Order? order = orders.where((Order o) => o.id == orderId).cast<Order?>().firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Order ${order.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${order.status.name.toUpperCase()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...order.items.map((CartItem item) {
              final String line = Money.formatCents(
                cents: item.lineTotalCents,
                currencyCode: order.currencyCode,
              );
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.product.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error, StackTrace? st) {
                        return Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined, size: 18),
                        );
                      },
                    ),
                  ),
                  title: Text(item.product.name),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text(line, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'Subtotal',
              value: Money.formatCents(cents: order.subtotalCents, currencyCode: order.currencyCode),
            ),
            _Row(
              label: 'Shipping',
              value: Money.formatCents(cents: order.shippingCents, currencyCode: order.currencyCode),
            ),
            _Row(
              label: 'Tax',
              value: Money.formatCents(cents: order.taxCents, currencyCode: order.currencyCode),
            ),
            const Divider(height: 24),
            _Row(
              label: 'Total',
              value: Money.formatCents(cents: order.totalCents, currencyCode: order.currencyCode),
              isEmphasis: true,
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
