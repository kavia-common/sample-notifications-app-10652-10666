import 'package:flutter/foundation.dart';

import 'cart_item.dart';

enum OrderStatus {
  pending,
  paid,
  cancelled,
}

@immutable
class Order {
  const Order({
    required this.id,
    required this.createdAtMillis,
    required this.status,
    required this.items,
    required this.subtotalCents,
    required this.shippingCents,
    required this.taxCents,
    required this.totalCents,
    required this.currencyCode,
  });

  final String id;
  final int createdAtMillis;
  final OrderStatus status;

  /// Item snapshot at order time.
  final List<CartItem> items;

  final int subtotalCents;
  final int shippingCents;
  final int taxCents;
  final int totalCents;
  final String currencyCode;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMillis);

  factory Order.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];
    final List<CartItem> items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((Map e) => CartItem.fromJson(e.cast<String, dynamic>()))
            .toList()
        : const <CartItem>[];

    final String statusStr = (json['status']?.toString() ?? 'pending').toLowerCase();
    final OrderStatus status = switch (statusStr) {
      'paid' => OrderStatus.paid,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };

    return Order(
      id: json['id']?.toString() ?? '',
      createdAtMillis:
          (json['createdAtMillis'] is num) ? (json['createdAtMillis'] as num).round() : 0,
      status: status,
      items: items,
      subtotalCents: (json['subtotalCents'] is num) ? (json['subtotalCents'] as num).round() : 0,
      shippingCents: (json['shippingCents'] is num) ? (json['shippingCents'] as num).round() : 0,
      taxCents: (json['taxCents'] is num) ? (json['taxCents'] as num).round() : 0,
      totalCents: (json['totalCents'] is num) ? (json['totalCents'] as num).round() : 0,
      currencyCode: json['currencyCode']?.toString() ?? 'usd',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAtMillis': createdAtMillis,
        'status': status.name,
        'items': items.map((CartItem e) => e.toJson()).toList(),
        'subtotalCents': subtotalCents,
        'shippingCents': shippingCents,
        'taxCents': taxCents,
        'totalCents': totalCents,
        'currencyCode': currencyCode,
      };
}
