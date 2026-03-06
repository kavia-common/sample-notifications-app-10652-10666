import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ecommerce/models/cart_item.dart';
import '../ecommerce/state/cart_state.dart';
import '../ecommerce/utils/money.dart';

class CartScreen extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartState cart = context.watch<CartState>();
    final List<CartItem> items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: <Widget>[
          if (items.isNotEmpty)
            TextButton(
              onPressed: cart.clear,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _EmptyCart(
                onShop: () => context.go('/'),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final CartItem item = items[index];
                        return _CartItemTile(item: item);
                      },
                    ),
                  ),
                  _CartSummary(
                    subtotalCents: cart.subtotalCents,
                    shippingCents: cart.shippingCents,
                    taxCents: cart.taxCents,
                    totalCents: cart.totalCents,
                    currencyCode: cart.currencyCode,
                    onCheckout: () => context.go('/checkout'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.shopping_cart_outlined, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products from Home to place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onShop,
              child: const Text('Go shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final CartState cart = context.read<CartState>();
    final int qty = item.quantity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.product.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? st) {
                  return Container(
                    width: 64,
                    height: 64,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Money.formatCents(
                      cents: item.product.priceCents,
                      currencyCode: item.product.currencyCode,
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(200)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Line: ${Money.formatCents(cents: item.lineTotalCents, currencyCode: item.product.currencyCode)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: <Widget>[
                IconButton(
                  tooltip: 'Remove one',
                  onPressed: qty > 1 ? () => cart.setQuantity(item.product.id, qty - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: 'Add one',
                  onPressed: () => cart.setQuantity(item.product.id, qty + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                TextButton(
                  onPressed: () => cart.remove(item.product.id),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.subtotalCents,
    required this.shippingCents,
    required this.taxCents,
    required this.totalCents,
    required this.currencyCode,
    required this.onCheckout,
  });

  final int subtotalCents;
  final int shippingCents;
  final int taxCents;
  final int totalCents;
  final String currencyCode;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _Row(
            label: 'Subtotal',
            value: Money.formatCents(cents: subtotalCents, currencyCode: currencyCode),
          ),
          _Row(
            label: 'Shipping',
            value: Money.formatCents(cents: shippingCents, currencyCode: currencyCode),
          ),
          _Row(
            label: 'Tax',
            value: Money.formatCents(cents: taxCents, currencyCode: currencyCode),
          ),
          const SizedBox(height: 8),
          _Row(
            label: 'Total',
            value: Money.formatCents(cents: totalCents, currencyCode: currencyCode),
            isEmphasis: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCheckout,
              child: const Text('Proceed to checkout'),
            ),
          ),
        ],
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
    final TextStyle base = isEmphasis
        ? const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)
        : TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(200));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: base)),
          Text(value, style: base),
        ],
      ),
    );
  }
}
