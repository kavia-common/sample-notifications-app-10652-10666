import 'package:flutter/foundation.dart';

import 'product.dart';

@immutable
class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  int get lineTotalCents => product.priceCents * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson((json['product'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{}),
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).round() : 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'product': product.toJson(),
        'quantity': quantity,
      };
}
