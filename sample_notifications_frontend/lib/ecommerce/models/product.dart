import 'package:flutter/foundation.dart';

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.priceCents,
    required this.currencyCode,
    required this.tags,
    required this.isFeatured,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int priceCents;
  final String currencyCode;
  final List<String> tags;
  final bool isFeatured;

  int get priceDollars => (priceCents / 100).round();

  String get priceLabel {
    final double value = priceCents / 100.0;
    // Keep formatting simple; screens can use intl for locale-specific formatting later.
    return '${currencyCode.toUpperCase()} ${value.toStringAsFixed(2)}';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final Object? tagsRaw = json['tags'];

    // Ensure the result is strongly typed as List<String> (avoids List<dynamic> inference).
    final List<String> tags = tagsRaw is List
        ? (tagsRaw.cast<dynamic>()).map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      priceCents: (json['priceCents'] is num) ? (json['priceCents'] as num).round() : 0,
      currencyCode: json['currencyCode']?.toString() ?? 'usd',
      tags: tags,
      isFeatured: json['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'priceCents': priceCents,
        'currencyCode': currencyCode,
        'tags': tags,
        'isFeatured': isFeatured,
      };
}
