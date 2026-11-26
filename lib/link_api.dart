import 'core/config/app_config.dart';

/// API endpoints. See https://dummyjson.com/docs/products
abstract final class AppLink {
  static String get server => AppConfig.baseUrl;

  static String get _products => '$server/products';

  /// GET — paginated list (`limit`, `skip`, `select`, `sortBy`, `order`).
  static String get products => _products;

  /// GET — full-text search (`q`), same paging parameters.
  static String get productsSearch => '$_products/search';

  /// GET — products of one category, same paging parameters.
  static String productsByCategory(String slug) =>
      '$_products/category/${Uri.encodeComponent(slug)}';

  /// GET — a single product.
  static String product(int id) => '$_products/$id';

  /// GET — categories as `{slug, name, url}` objects.
  static String get categories => '$_products/categories';
}
