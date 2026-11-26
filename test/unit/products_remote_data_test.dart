import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:real_estate/core/class/crud.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/data/datasource/remote/products_remote_data.dart';
import 'package:real_estate/data/model/category.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/data/model/product_page.dart';
import 'package:real_estate/data/model/product_query.dart';
import 'package:real_estate/link_api.dart';

import '../helpers/test_doubles.dart';

void main() {
  late List<Uri> requests;
  late http.Response Function(Uri url) respond;

  ProductsRemoteData build() {
    final Crud crud = Crud(
      client: MockClient((http.Request request) async {
        requests.add(request.url);
        return respond(request.url);
      }),
      connectivityCheck: () async => true,
    );
    return ProductsRemoteData(crud);
  }

  setUp(() {
    requests = <Uri>[];
    respond = (_) => jsonResponse(fixtureText('products_page'));
  });

  group('fetchProducts', () {
    test('plain list hits /products with paging and select', () async {
      final Either<StatusRequest, ProductPage> result = await build()
          .fetchProducts(const ProductQuery(skip: 20));
      expect(result.right.products, hasLength(2));
      final Uri url = requests.single;
      expect(url.toString(), startsWith(AppLink.products));
      expect(url.path, '/products');
      expect(url.queryParameters['limit'], '10');
      expect(url.queryParameters['skip'], '20');
      expect(url.queryParameters['select'], ProductQuery.listFields.join(','));
      expect(url.queryParameters.containsKey('q'), isFalse);
    });

    test('search hits /products/search with q', () async {
      await build().fetchProducts(const ProductQuery(search: '  chair  '));
      expect(requests.single.path, '/products/search');
      expect(requests.single.queryParameters['q'], 'chair');
    });

    test('category hits /products/category/{slug}', () async {
      await build().fetchProducts(
        const ProductQuery(categorySlug: 'home-decoration'),
      );
      expect(requests.single.path, '/products/category/home-decoration');
    });

    test('search wins over category (the API cannot combine them)', () async {
      await build().fetchProducts(
        const ProductQuery(search: 'lamp', categorySlug: 'furniture'),
      );
      expect(requests.single.path, '/products/search');
    });

    test('sort adds sortBy and order', () async {
      await build().fetchProducts(
        const ProductQuery(sort: ProductSort.priceDesc),
      );
      expect(requests.single.queryParameters['sortBy'], 'price');
      expect(requests.single.queryParameters['order'], 'desc');
    });

    test('the same query is served from the cache', () async {
      final ProductsRemoteData data = build();
      await data.fetchProducts(const ProductQuery());
      await data.fetchProducts(const ProductQuery());
      expect(requests, hasLength(1));
    });

    test('a body without products is an unexpected response', () async {
      respond = (_) => jsonResponse('{"message":"nope"}');
      final Either<StatusRequest, ProductPage> result = await build()
          .fetchProducts(const ProductQuery());
      expect(result.left, StatusRequest.unexpectedResponse);
    });

    test('a list body is an unexpected response', () async {
      respond = (_) => jsonResponse('[]');
      expect(
        (await build().fetchProducts(const ProductQuery())).left,
        StatusRequest.unexpectedResponse,
      );
    });

    test('a server error is passed through and not cached', () async {
      respond = (_) => jsonResponse('{}', status: 500);
      final ProductsRemoteData data = build();
      expect(
        (await data.fetchProducts(const ProductQuery())).left,
        StatusRequest.serverFailure,
      );
      respond = (_) => jsonResponse(fixtureText('products_page'));
      expect((await data.fetchProducts(const ProductQuery())).isRight, isTrue);
      expect(requests, hasLength(2));
    });
  });

  group('fetchProduct', () {
    test('hits /products/{id} and parses the product', () async {
      respond = (_) => jsonResponse(fixtureText('product'));
      final Either<StatusRequest, Product> result = await build().fetchProduct(
        14,
      );
      expect(requests.single.path, '/products/14');
      expect(result.right.id, 14);
    });

    test('404 is not found', () async {
      respond = (_) => jsonResponse('{"message":"x"}', status: 404);
      expect(
        (await build().fetchProduct(99999)).left,
        StatusRequest.notFoundFailure,
      );
    });

    test('a product without a title is an unexpected response', () async {
      respond = (_) => jsonResponse('{"id":1}');
      expect(
        (await build().fetchProduct(1)).left,
        StatusRequest.unexpectedResponse,
      );
    });
  });

  group('fetchCategories', () {
    test('hits /products/categories and parses all 24', () async {
      respond = (_) => jsonResponse(fixtureText('categories'));
      final Either<StatusRequest, List<Category>> result = await build()
          .fetchCategories();
      expect(requests.single.path, '/products/categories');
      expect(result.right, hasLength(24));
      expect(result.right.first.slug, 'beauty');
    });

    test('an object body is an unexpected response', () async {
      respond = (_) => jsonResponse('{}');
      expect(
        (await build().fetchCategories()).left,
        StatusRequest.unexpectedResponse,
      );
    });
  });
}
