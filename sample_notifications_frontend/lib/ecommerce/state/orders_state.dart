import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class OrdersState extends ChangeNotifier {
  final List<Order> _orders = <Order>[];

  List<Order> get orders => List<Order>.unmodifiable(_orders);

  /// PUBLIC_INTERFACE
  /// Places an order from a cart snapshot.
  ///
  /// This function is synchronous by design to avoid UI context across async gaps.
  /// A future payment implementation can provide an async method that only updates
  /// primitive state and triggers navigation from build.
  Order placeOrder({
    required List<CartItem> cartItems,
    required int subtotalCents,
    required int shippingCents,
    required int taxCents,
    required int totalCents,
    required String currencyCode,
  }) {
    final String id = _generateOrderId();

    final Order order = Order(
      id: id,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      status: OrderStatus.paid,
      items: List<CartItem>.unmodifiable(cartItems),
      subtotalCents: subtotalCents,
      shippingCents: shippingCents,
      taxCents: taxCents,
      totalCents: totalCents,
      currencyCode: currencyCode,
    );

    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  String _generateOrderId() {
    final Random r = Random();
    final int stamp = DateTime.now().millisecondsSinceEpoch;
    final int suffix = r.nextInt(900000) + 100000;
    return 'o-$stamp-$suffix';
  }
}
