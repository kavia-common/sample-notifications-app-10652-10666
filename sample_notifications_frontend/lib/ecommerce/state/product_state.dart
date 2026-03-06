import 'package:flutter/foundation.dart';

import '../data/catalog_repository.dart';
import '../models/product.dart';

class ProductState extends ChangeNotifier {
  ProductState() : _products = CatalogRepository.getProducts();

  final List<Product> _products;

  List<Product> get products => List<Product>.unmodifiable(_products);

  List<Product> get featuredProducts =>
      List<Product>.unmodifiable(_products.where((Product p) => p.isFeatured));

  /// PUBLIC_INTERFACE
  /// Returns a product by id if it exists.
  Product? findById(String id) {
    try {
      return _products.firstWhere((Product p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
