import 'package:either_dart/either.dart';

import '../../../core/class/crud.dart';
import '../../../core/class/query_cache.dart';
import '../../../core/class/status_request.dart';
import '../../../link_api.dart';
import '../../model/category.dart';
import '../../model/product.dart';
import '../../model/product_page.dart';
import '../../model/product_query.dart';

/// Products API. GET results are cached per URL (see [QueryCache]).
class ProductsRemoteData {
  ProductsRemoteData(this._crud, {QueryCache? cache})
    : _cache = cache ?? QueryCache();

  final Crud _crud;
  final QueryCache _cache;

  Future<Either<StatusRequest, ProductPage>> fetchProducts(ProductQuery query) {
    final String url = query.isSearch
        ? AppLink.productsSearch
        : (query.categorySlug == null
              ? AppLink.products
              : AppLink.productsByCategory(query.categorySlug!));
    final Map<String, String> params = query.toQueryParameters();

    return _cache.fetch<ProductPage>(_key(url, params), () async {
      final Either<StatusRequest, ApiResult> result = await _crud.getJson(
        url,
        query: params,
      );
      if (result.isLeft) return Left(result.left);
      final Map<String, dynamic>? body = result.right.map;
      final ProductPage? page = body == null
          ? null
          : ProductPage.tryParse(body);
      return page == null
          ? const Left(StatusRequest.unexpectedResponse)
          : Right(page);
    });
  }

  Future<Either<StatusRequest, Product>> fetchProduct(int id) {
    final String url = AppLink.product(id);
    return _cache.fetch<Product>(url, () async {
      final Either<StatusRequest, ApiResult> result = await _crud.getJson(url);
      if (result.isLeft) return Left(result.left);
      final Map<String, dynamic>? body = result.right.map;
      final Product? product = body == null ? null : Product.tryParse(body);
      return product == null
          ? const Left(StatusRequest.unexpectedResponse)
          : Right(product);
    });
  }

  Future<Either<StatusRequest, List<Category>>> fetchCategories() {
    final String url = AppLink.categories;
    return _cache.fetch<List<Category>>(url, () async {
      final Either<StatusRequest, ApiResult> result = await _crud.getJson(url);
      if (result.isLeft) return Left(result.left);
      final List<dynamic>? body = result.right.list;
      return body == null
          ? const Left(StatusRequest.unexpectedResponse)
          : Right(Category.listFrom(body));
    });
  }

  static String _key(String url, Map<String, String> params) {
    final List<String> keys = params.keys.toList()..sort();
    return '$url?${keys.map((String k) => '$k=${params[k]}').join('&')}';
  }
}
