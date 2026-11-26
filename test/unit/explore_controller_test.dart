import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:real_estate/controller/explore/explore_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/data/model/product_filter.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<ExploreController> _start(FakeHomeApi api) async {
  await setUpScreenDependencies(handler: api.handle);
  final ExploreController controller = Get.put(ExploreController());
  await _flush();
  return controller;
}

Future<void> _flush() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<int> _ids(List<Product> items) => items.map((Product p) => p.id).toList();

Iterable<String> _keys(FakeHomeApi api) => api.requests.map(FakeHomeApi.keyOf);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExploreController', () {
    test('starts with categories and the first API page', () async {
      final ExploreController c = await _start(FakeHomeApi.explore());
      expect(c.categories, hasLength(24));
      expect(c.results.status.value, StatusRequest.success);
      expect(_ids(c.results.products), <int>[11, 12]);
      expect(c.layout.value, ExploreLayout.list);
    });

    test('typing searches once, after the pause', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=lamp'] = jsonResponse(
          pageJson(<int>[31], total: 9),
        );
      final ExploreController c = await _start(api);
      fakeAsync((FakeAsync async) {
        c.onSearchChanged('la');
        async.elapse(const Duration(milliseconds: 200));
        c.onSearchChanged('lamp ');
        async.elapse(const Duration(milliseconds: 399));
        expect(c.search.value, '');
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
      });
      await _flush();
      expect(c.search.value, 'lamp');
      expect(_keys(api).where((String k) => k.contains('q=')), <String>[
        '/products/search?q=lamp',
      ]);
      expect(_ids(c.results.products), <int>[31]);
      expect(c.results.total.value, 9);
    });

    test('submitting searches now and drops the pending one', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=desk'] = jsonResponse(
          pageJson(<int>[41]),
        );
      final ExploreController c = await _start(api);
      fakeAsync((FakeAsync async) {
        c.onSearchChanged('des');
        c.submitSearch('desk');
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
      });
      await _flush();
      expect(_keys(api).where((String k) => k.contains('q=')), <String>[
        '/products/search?q=desk',
      ]);
      final int count = api.requests.length;
      c.submitSearch(' desk ');
      expect(api.requests, hasLength(count), reason: 'same search');
    });

    test('a chip loads that category page from the API', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        );
      final ExploreController c = await _start(api);
      c.selectCategory('beauty');
      await _flush();
      expect(c.filter.value.categories, <String>{'beauty'});
      expect(_ids(c.results.products), <int>[21]);
      c.selectCategory(null);
      await _flush();
      expect(c.filter.value.categories, isEmpty);
      expect(_ids(c.results.products), <int>[11, 12]);
    });

    test('search with a category is filtered on the device', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=a'] = jsonResponse(pageJson(<int>[1]))
        ..responses['/products/search?q=a&all'] = jsonResponse(
          listingsJson(exploreListings),
        );
      final ExploreController c = await _start(api);
      c.submitSearch('a');
      await _flush();
      c.selectCategory('furniture');
      await _flush();
      expect(_keys(api).last, '/products/search?q=a&all');
      expect(_ids(c.results.products), <int>[3, 5]);
      expect(c.results.total.value, 2);
    });

    test('sheet filters narrow the whole set and count it', () async {
      final FakeHomeApi api = FakeHomeApi.explore();
      final ExploreController c = await _start(api);
      c.openFilters();
      await _flush();
      c
        ..toggleDraftCategory('beauty')
        ..toggleDraftCategory('furniture')
        ..setDraftMinStock(10)
        ..applyDraft();
      await _flush();
      expect(_keys(api).last, '/products?all');
      expect(_ids(c.results.products), <int>[2, 3, 5]);
      expect(c.results.total.value, 3);
      expect(c.results.hasMore.value, isFalse);
    });

    test(
      'one category with a local filter fetches only that category',
      () async {
        final FakeHomeApi api = FakeHomeApi.explore()
          ..responses['/products/category/beauty?all'] = jsonResponse(
            listingsJson(exploreListings.take(2).toList()),
          );
        final ExploreController c = await _start(api);
        c.openFilters();
        await _flush();
        c
          ..toggleDraftCategory('beauty')
          ..setDraftMinRating(4)
          ..applyDraft();
        await _flush();
        expect(_keys(api).last, '/products/category/beauty?all');
        expect(_ids(c.results.products), <int>[1]);
      },
    );

    test('a slower old search never replaces a newer one', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=old'] = jsonResponse(pageJson(<int>[1]))
        ..holds['/products/search?q=old'] = Completer<void>()
        ..responses['/products/search?q=new'] = jsonResponse(
          pageJson(<int>[2]),
        );
      final ExploreController c = await _start(api);
      c.submitSearch('old');
      c.submitSearch('new');
      await _flush();
      api.holds['/products/search?q=old']!.complete();
      await _flush();
      expect(_ids(c.results.products), <int>[2]);
    });

    test('opening the sheet copies the filter and loads spans once', () async {
      final FakeHomeApi api = FakeHomeApi.explore();
      final ExploreController c = await _start(api);
      c.filter.value = ProductFilter.none.withMinRating(2);
      c.openFilters();
      await _flush();
      expect(c.draft.value.minRating, 2);
      expect(c.boundsStatus.value, StatusRequest.success);
      expect(c.bounds.value!.price!.start, 5.99);
      expect(c.bounds.value!.weight!.end, 10);
      final int count = api.requests.length;
      c.openFilters();
      await _flush();
      expect(api.requests, hasLength(count), reason: 'spans are kept');
    });

    test('failed spans can be loaded again', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products?all'] = jsonResponse('', status: 500);
      final ExploreController c = await _start(api);
      c.openFilters();
      await _flush();
      expect(c.boundsStatus.value, StatusRequest.serverFailure);
      api.responses['/products?all'] = jsonResponse(
        listingsJson(exploreListings),
      );
      await c.loadBounds();
      expect(c.boundsStatus.value, StatusRequest.success);
    });

    test('sliders at the full span leave no range filter', () async {
      final ExploreController c = await _start(FakeHomeApi.explore());
      c.setDraftPrice(0.2, 0.8);
      expect(c.draft.value.price, isNull, reason: 'no spans yet');
      c.openFilters();
      await _flush();
      c.setDraftPrice(0, 1);
      expect(c.draft.value.price, isNull);
      c.setDraftPrice(0, 0.5);
      expect(c.draft.value.price!.start, 5.99);
      expect(c.draft.value.price!.end, lessThan(1499.99));
      c.setDraftWeight(1, 10);
      expect(c.draft.value.weight, isNull);
      c.setDraftWeight(2, 8);
      expect(c.draft.value.weight, const ValueRange(2, 8));
    });

    test(
      'reset clears the draft only; apply without change does nothing',
      () async {
        final FakeHomeApi api = FakeHomeApi.explore();
        final ExploreController c = await _start(api);
        c.filter.value = ProductFilter.none.withMinStock(20);
        c.openFilters();
        await _flush();
        c.resetDraft();
        expect(c.draft.value, ProductFilter.none);
        expect(c.filter.value.minStock, 20);

        c.draft.value = c.filter.value;
        final int count = api.requests.length;
        c.applyDraft();
        await _flush();
        expect(api.requests, hasLength(count));
      },
    );

    test(
      'ranges kept from an earlier search are fitted to the spans',
      () async {
        final ExploreController c = await _start(FakeHomeApi.explore());
        c.filter.value = ProductFilter.none
            .withPrice(const ValueRange(10, 5000))
            .withWeight(const ValueRange(20, 40));
        c.openFilters();
        await _flush();
        expect(c.draft.value.price, const ValueRange(10, 1499.99));
        expect(c.draft.value.weight, isNull, reason: 'no overlap: any weight');
        expect(c.filter.value.weight, const ValueRange(20, 40));

        c.filter.value = ProductFilter.none
            .withPrice(const ValueRange(1, 5000))
            .withWeight(const ValueRange(5, 40));
        c.openFilters();
        await _flush();
        expect(c.draft.value.price, isNull, reason: 'covers the whole span');
        expect(c.draft.value.weight, const ValueRange(5, 10));
      },
    );

    test(
      'spans of an earlier search are dropped when a new one fails',
      () async {
        final FakeHomeApi api = FakeHomeApi.explore()
          ..responses['/products/search?q=x'] = jsonResponse(pageJson(<int>[1]))
          ..responses['/products/search?q=x&all'] = jsonResponse(
            '',
            status: 500,
          );
        final ExploreController c = await _start(api);
        c.openFilters();
        await _flush();
        expect(c.bounds.value, isNotNull);
        c.submitSearch('x');
        await _flush();
        c.openFilters();
        await _flush();
        expect(c.boundsStatus.value, StatusRequest.serverFailure);
        expect(c.bounds.value, isNull);
      },
    );

    test('chips that failed to load are asked for again on retry', () async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/categories'] = jsonResponse('', status: 500);
      final ExploreController c = await _start(api);
      expect(c.categories, isEmpty);
      api.responses['/products/categories'] = jsonResponse(
        fixtureText('categories'),
      );
      await c.retry();
      await _flush();
      expect(c.categories, hasLength(24));
    });

    test('the layout switches between list and grid', () async {
      final ExploreController c = await _start(FakeHomeApi.explore());
      c.toggleLayout();
      expect(c.layout.value, ExploreLayout.grid);
      c.toggleLayout();
      expect(c.layout.value, ExploreLayout.list);
    });

    test('a pending search is cancelled when the controller closes', () async {
      final FakeHomeApi api = FakeHomeApi.explore();
      final ExploreController c = await _start(api);
      fakeAsync((FakeAsync async) {
        c.onSearchChanged('gone');
        Get.delete<ExploreController>();
        async.elapse(const Duration(seconds: 1));
      });
      expect(c.search.value, '');
    });
  });

  group('MainController explore entry', () {
    test('an entry is taken once', () {
      final MainController main = MainController()
        ..openExplore(ExploreEntry.filters);
      expect(main.tab.value, MainTab.explore);
      expect(main.takeExploreEntry(), ExploreEntry.filters);
      expect(main.takeExploreEntry(), isNull);
    });
  });
}
