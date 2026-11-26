import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate/controller/shared/product_pager.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/data/model/product_page.dart';
import 'package:real_estate/data/model/product_query.dart';

ProductPage _page(List<int> ids, {int skip = 0, int? total}) => ProductPage(
  products: <Product>[
    for (final int id in ids) Product(id: id, title: 'P$id', price: id * 1.0),
  ],
  total: total ?? ids.length,
  skip: skip,
  limit: ids.length,
);

List<int> _ids(List<Product> items) => items.map((Product p) => p.id).toList();

/// Answers each query from [answers] by its skip, or waits on [holds].
class _Api {
  final Map<int, Either<StatusRequest, ProductPage>> answers =
      <int, Either<StatusRequest, ProductPage>>{};
  final Map<String, Completer<void>> holds = <String, Completer<void>>{};
  final List<ProductQuery> calls = <ProductQuery>[];

  Future<Either<StatusRequest, ProductPage>> fetch(ProductQuery q) async {
    calls.add(q);
    final Completer<void>? hold = holds[q.search];
    if (hold != null) await hold.future;
    return answers[q.skip] ?? const Left(StatusRequest.serverFailure);
  }
}

void main() {
  late _Api api;
  late bool closed;
  late ProductPager pager;

  setUp(() {
    api = _Api();
    closed = false;
    pager = ProductPager(fetch: api.fetch, isClosed: () => closed);
  });

  test('a first page shows its items and the API total', () async {
    api.answers[0] = Right(_page(<int>[1, 2], total: 30));
    await pager.load(const ProductQuery());
    expect(pager.status.value, StatusRequest.success);
    expect(_ids(pager.products), <int>[1, 2]);
    expect(pager.total.value, 30);
    expect(pager.hasMore.value, isTrue);
  });

  test('a refined load shows the narrowed set with no more pages', () async {
    api.answers[0] = Right(_page(<int>[1, 2, 3], total: 300));
    await pager.load(
      const ProductQuery.all(),
      refine: (List<Product> items) =>
          items.where((Product p) => p.id != 2).toList(),
    );
    expect(_ids(pager.products), <int>[1, 3]);
    expect(pager.total.value, 2);
    expect(pager.hasMore.value, isFalse);
    await pager.loadMore();
    expect(api.calls, hasLength(1));
  });

  test('nothing left after refining is the empty state', () async {
    api.answers[0] = Right(_page(<int>[1]));
    await pager.load(
      const ProductQuery.all(),
      refine: (List<Product> _) => <Product>[],
    );
    expect(pager.status.value, StatusRequest.empty);
    expect(pager.total.value, 0);
  });

  test('a failure is shown and reload asks again', () async {
    await pager.load(const ProductQuery());
    expect(pager.status.value, StatusRequest.serverFailure);
    api.answers[0] = Right(_page(<int>[7]));
    await pager.reload();
    expect(_ids(pager.products), <int>[7]);
  });

  test('reload before any load does nothing', () async {
    await pager.reload();
    expect(api.calls, isEmpty);
  });

  test('a newer load wins over a slower older one', () async {
    api.holds['old'] = Completer<void>();
    api.answers[0] = Right(_page(<int>[1]));
    final Future<void> older = pager.load(const ProductQuery(search: 'old'));
    await pager.load(const ProductQuery(search: 'new'));
    api.holds['old']!.complete();
    await older;
    expect(pager.generation.value, 2);
    expect(_ids(pager.products), <int>[1]);
    expect(pager.status.value, StatusRequest.success);
  });

  test('a response after closing is dropped', () async {
    api.holds['x'] = Completer<void>();
    api.answers[0] = Right(_page(<int>[1]));
    final Future<void> pending = pager.load(const ProductQuery(search: 'x'));
    closed = true;
    api.holds['x']!.complete();
    await pending;
    expect(pager.status.value, StatusRequest.loading);
  });

  test('loadMore appends pages until the total, a failure stops it', () async {
    api.answers[0] = Right(_page(<int>[1, 2], total: 30));
    await pager.load(const ProductQuery(limit: 2));
    api.answers[2] = Right(_page(<int>[3, 4], skip: 2, total: 30));
    await pager.loadMore();
    expect(_ids(pager.products), <int>[1, 2, 3, 4]);

    await pager.loadMore();
    expect(pager.loadMoreError.value, StatusRequest.serverFailure);
    expect(pager.isLoadingMore.value, isFalse);
    final int calls = api.calls.length;
    await pager.loadMore();
    expect(api.calls, hasLength(calls), reason: 'no automatic retry');

    api.answers[4] = Right(_page(<int>[5], skip: 4, total: 5));
    await pager.retryMore();
    expect(_ids(pager.products), <int>[1, 2, 3, 4, 5]);
    expect(pager.hasMore.value, isFalse);
  });
}
