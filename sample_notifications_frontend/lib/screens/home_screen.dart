import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ecommerce/models/product.dart';
import '../ecommerce/state/cart_state.dart';
import '../ecommerce/state/product_state.dart';
import '../ecommerce/utils/money.dart';
import '../notifications/notification_service.dart';

class HomeScreen extends StatelessWidget {
  /// PUBLIC_INTERFACE
  const HomeScreen({super.key});

  Future<void> _triggerLocalTestNotification() async {
    // No UI calls after await.
    await NotificationService.instance.showNotificationFromData(<String, dynamic>{
      'title': 'New message',
      'body': 'You have a new chat message',
      'defaultDeepLink': 'myapp://chat?threadId=42',
      'actionTitles': 'Open Chat,Open Orders',
      'actionDeepLinks': 'myapp://chat?threadId=42,myapp://orders',
      'notificationId': '9876',
      'category': 'chat',
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> products = context.select<ProductState, List<Product>>(
      (ProductState s) => s.products,
    );
    final int cartCount = context.select<CartState, int>((CartState c) => c.itemCount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Token',
            onPressed: () => context.go('/token'),
            icon: const Icon(Icons.key),
          ),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IconButton(
                tooltip: 'Cart',
                onPressed: () => context.go('/cart'),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Orders',
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Demo: actionable notifications + deep links are still enabled.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _triggerLocalTestNotification,
                      child: const Text('Test notification'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...products.map((Product p) => _ProductTile(product: p)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final CartState cart = context.watch<CartState>();
    final int qty = cart.quantityFor(product.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? st) {
                  return Container(
                    width: 84,
                    height: 84,
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
                    product.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Money.formatCents(cents: product.priceCents, currencyCode: product.currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => cart.add(product, quantity: 1),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(qty > 0 ? 'Add more' : 'Add to cart'),
                      ),
                      const SizedBox(width: 12),
                      if (qty > 0)
                        Text(
                          'In cart: $qty',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
