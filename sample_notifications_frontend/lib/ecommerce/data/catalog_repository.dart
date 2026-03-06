import '../models/product.dart';

class CatalogRepository {
  CatalogRepository._();

  /// PUBLIC_INTERFACE
  /// Returns an in-memory catalog. Replace with API/db later.
  static List<Product> getProducts() {
    return const <Product>[
      Product(
        id: 'p-001',
        name: 'Wireless Headphones',
        description: 'Comfort fit, noise isolation, 30h battery.',
        imageUrl: 'https://picsum.photos/seed/headphones/800/800',
        priceCents: 7999,
        currencyCode: 'usd',
        tags: <String>['audio', 'wireless'],
        isFeatured: true,
      ),
      Product(
        id: 'p-002',
        name: 'Smart Watch',
        description: 'Fitness tracking, notifications, and GPS.',
        imageUrl: 'https://picsum.photos/seed/watch/800/800',
        priceCents: 12999,
        currencyCode: 'usd',
        tags: <String>['wearable'],
        isFeatured: true,
      ),
      Product(
        id: 'p-003',
        name: 'Sneakers',
        description: 'Everyday comfort for walking and running.',
        imageUrl: 'https://picsum.photos/seed/sneakers/800/800',
        priceCents: 5999,
        currencyCode: 'usd',
        tags: <String>['fashion'],
        isFeatured: false,
      ),
      Product(
        id: 'p-004',
        name: 'Backpack',
        description: 'Lightweight travel backpack with laptop sleeve.',
        imageUrl: 'https://picsum.photos/seed/backpack/800/800',
        priceCents: 4599,
        currencyCode: 'usd',
        tags: <String>['travel'],
        isFeatured: false,
      ),
      Product(
        id: 'p-005',
        name: 'Coffee Grinder',
        description: 'Consistent grind, easy to clean, compact size.',
        imageUrl: 'https://picsum.photos/seed/grinder/800/800',
        priceCents: 3499,
        currencyCode: 'usd',
        tags: <String>['kitchen'],
        isFeatured: false,
      ),
    ];
  }
}
