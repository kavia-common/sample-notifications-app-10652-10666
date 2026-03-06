import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartState extends ChangeNotifier {
  final Map<String, CartItem> _itemsByProductId = <String, CartItem>{};

  List<CartItem> get items => List<CartItem>.unmodifiable(_itemsByProductId.values);

  int get itemCount => _itemsByProductId.values.fold<int>(0, (int sum, CartItem e) => sum + e.quantity);

  bool containsProduct(String productId) => _itemsByProductId.containsKey(productId);

  int quantityFor(String productId) => _itemsByProductId[productId]?.quantity ?? 0;

  int get subtotalCents =>
      _itemsByProductId.values.fold<int>(0, (int sum, CartItem e) => sum + e.lineTotalCents);

  /// For demo: flat shipping if cart has items.
  int get shippingCents => subtotalCents > 0 ? 599 : 0;

  /// For demo: simple 8% tax.
  int get taxCents => (subtotalCents * 0.08).round();

  int get totalCents => subtotalCents + shippingCents + taxCents;

  String get currencyCode {
    // Assume single currency for demo; prefer first item currency if present.
    for (final CartItem item in _itemsByProductId.values) {
      return item.product.currencyCode;
    }
    return 'usd';
  }

  /// PUBLIC_INTERFACE
  void add(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;

    final CartItem? existing = _itemsByProductId[product.id];
    if (existing == null) {
      _itemsByProductId[product.id] = CartItem(product: product, quantity: quantity);
    } else {
      _itemsByProductId[product.id] = existing.copyWith(quantity: existing.quantity + quantity);
    }
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _itemsByProductId.remove(productId);
      notifyListeners();
      return;
    }

    final CartItem? existing = _itemsByProductId[productId];
    if (existing == null) return;

    _itemsByProductId[productId] = existing.copyWith(quantity: quantity);
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  void remove(String productId) {
    if (_itemsByProductId.remove(productId) != null) {
      notifyListeners();
    }
  }

  /// PUBLIC_INTERFACE
  void clear() {
    if (_itemsByProductId.isEmpty) return;
    _itemsByProductId.clear();
    notifyListeners();
  }

  /// PUBLIC_INTERFACE
  /// Provides an immutable snapshot for order creation.
  List<CartItem> snapshotItems() {
    // Deep-ish copy: CartItem and Product are immutable, so just copy list.
    return List<CartItem>.unmodifiable(_itemsByProductId.values.toList());
  }
}
