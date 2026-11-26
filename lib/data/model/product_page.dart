import '../../core/functions/json_parsers.dart';
import 'product.dart';

/// One page of `{products, total, skip, limit}`.
class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  /// Returns `null` when the body has no `products` list, so the caller can
  /// report an unexpected response instead of an empty result.
  static ProductPage? tryParse(Map<String, dynamic> json) {
    final Object? raw = json['products'];
    if (raw is! List) return null;
    final List<Product> products = List<Product>.unmodifiable(
      raw
          .whereType<Map<String, dynamic>>()
          .map(Product.tryParse)
          .whereType<Product>(),
    );
    final int skip = jsonInt(json['skip']) ?? 0;
    return ProductPage(
      products: products,
      total: jsonInt(json['total']) ?? skip + products.length,
      skip: skip,
      limit: jsonInt(json['limit']) ?? products.length,
    );
  }

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  /// Whether another page exists after this one.
  bool get hasMore => skip + products.length < total && products.isNotEmpty;
}
