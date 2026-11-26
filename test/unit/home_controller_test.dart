import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:real_estate/controller/auth/splash_controller.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/home/home_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/core/functions/greeting.dart';
import 'package:real_estate/core/localization/app_strings.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/routes.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<HomeController> _start(FakeHomeApi api) async {
  await setUpScreenDependencies(handler: api.handle);
  final HomeController controller = Get.put(HomeController());
  await _flush();
  return controller;
}

Future<void> _flush() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<int> _ids(List<Product> items) => items.map((Product p) => p.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeController', () {
    test('loads featured, categories and the first grid page', () async {
      final HomeController c = await _start(FakeHomeApi.standard());
      expect(c.featuredStatus.value, StatusRequest.success);
      expect(_ids(c.featured), <int>[1, 2]);
      expect(c.categories, hasLength(24));
      expect(c.status.value, StatusRequest.success);
      expect(_ids(c.products), <int>[11, 12]);
    });

    test('featured asks for the best rated listings', () async {
      final FakeHomeApi api = FakeHomeApi.standard();
      await _start(api);
      final Uri featured = api.requests.firstWhere(
        (Uri u) => u.queryParameters['sortBy'] == 'rating',
      );
      expect(featured.queryParameters['order'], 'desc');
      expect(
        featured.queryParameters['limit'],
        '${HomeController.featuredCount}',
      );
    });

    test(
      'a failing section shows its own error; categories fail quietly',
      () async {
        final FakeHomeApi api = FakeHomeApi.standard()
          ..responses['featured'] = jsonResponse('oops', status: 500)
          ..responses['/products/categories'] = jsonResponse('', status: 500);
        final HomeController c = await _start(api);
        expect(c.featuredStatus.value.isFailure, isTrue);
        expect(c.categories, isEmpty);
        expect(c.status.value, StatusRequest.success);
      },
    );

    test('an empty page is the empty state', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(pageJson(<int>[]));
      final HomeController c = await _start(api);
      expect(c.status.value, StatusRequest.empty);
    });

    test('selecting a category loads that category', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        );
      final HomeController c = await _start(api);
      c.selectCategory('beauty');
      await _flush();
      expect(c.selectedCategory.value, 'beauty');
      expect(_ids(c.products), <int>[21]);
    });

    test('a late answer for the previous category is dropped', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        )
        ..holds['/products/category/beauty'] = Completer<void>()
        ..responses['/products/category/laptops'] = jsonResponse(
          pageJson(<int>[31]),
        );
      final HomeController c = await _start(api);
      c.selectCategory('beauty');
      c.selectCategory('laptops');
      await _flush();
      expect(_ids(c.products), <int>[31]);
      api.holds['/products/category/beauty']!.complete();
      await _flush();
      expect(_ids(c.products), <int>[31]);
      expect(c.selectedCategory.value, 'laptops');
    });

    test('loadMore appends the next page and stops at the total', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11, 12], total: 3),
        )
        ..responses['/products?skip=10'] = jsonResponse(
          pageJson(<int>[13], total: 3, skip: 10),
        );
      final HomeController c = await _start(api);
      expect(c.hasMore.value, isTrue);
      await c.loadMore();
      expect(_ids(c.products), <int>[11, 12, 13]);
      expect(c.hasMore.value, isFalse);
      await c.loadMore();
      expect(
        api.requests.where((Uri u) => u.path == '/products'),
        hasLength(3),
      );
    });

    test('a failed loadMore clears the spinner and can be retried', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11, 12], total: 3),
        )
        ..responses['/products?skip=10'] = jsonResponse('', status: 500);
      final HomeController c = await _start(api);
      await c.loadMore();
      expect(c.isLoadingMore.value, isFalse);
      expect(_ids(c.products), <int>[11, 12]);
      expect(c.status.value, StatusRequest.success);
      expect(c.loadMoreError.value, isNotNull);

      // Scrolling again does not hammer a failing server.
      final int sent = api.requests.length;
      await c.loadMore();
      expect(api.requests.length, sent);

      api.responses['/products?skip=10'] = jsonResponse(
        pageJson(<int>[13], total: 3, skip: 10),
      );
      await c.retryMore();
      expect(_ids(c.products), <int>[11, 12, 13]);
      expect(c.loadMoreError.value, isNull);
    });

    test('refresh keeps loaded sections and reloads failed ones', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['featured'] = jsonResponse('', status: 500);
      final HomeController c = await _start(api);
      expect(c.featuredStatus.value, isNot(StatusRequest.success));
      api.responses['featured'] = jsonResponse(pageJson(<int>[1, 2]));

      final List<StatusRequest> gridStates = <StatusRequest>[];
      final Worker worker = ever(c.status, gridStates.add);
      await c.refreshAll();
      worker.dispose();

      expect(c.featuredStatus.value, StatusRequest.success);
      expect(_ids(c.featured), <int>[1, 2]);
      expect(gridStates, isEmpty);
      expect(_ids(c.products), <int>[11, 12]);
    });

    test('a page that lands after a category switch is dropped', () async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11, 12], total: 3),
        )
        ..responses['/products?skip=10'] = jsonResponse(
          pageJson(<int>[13], total: 3, skip: 10),
        )
        ..holds['/products?skip=10'] = Completer<void>()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        );
      final HomeController c = await _start(api);
      final Future<void> more = c.loadMore();
      c.selectCategory('beauty');
      await _flush();
      api.holds['/products?skip=10']!.complete();
      await more;
      expect(_ids(c.products), <int>[21]);
      expect(c.isLoadingMore.value, isFalse);
    });

    test('identical requests are served from the cache', () async {
      final FakeHomeApi api = FakeHomeApi.standard();
      final HomeController c = await _start(api);
      final int before = api.requests.length;
      api.responses['/products/category/beauty'] = jsonResponse(
        pageJson(<int>[21]),
      );
      c.selectCategory('beauty');
      await _flush();
      c.selectCategory(null);
      await _flush();
      expect(api.requests.length, before + 1);
      expect(_ids(c.products), <int>[11, 12]);
    });
  });

  group('FavoritesController', () {
    test('toggles and restores saved ids', () async {
      await setUpScreenDependencies();
      final FavoritesController first = Get.find<FavoritesController>();
      await first.toggle(7);
      await first.toggle(9);
      await first.toggle(7);
      expect(first.ids, <int>{9});
      final FavoritesController second = FavoritesController()..onInit();
      expect(second.isFavorite(9), isTrue);
      expect(second.isFavorite(7), isFalse);
    });

    test('ignores corrupt stored values', () async {
      await setUpScreenDependencies(
        prefs: <String, Object>{
          FavoritesController.storageKey: <String>['4', 'x', ''],
        },
      );
      expect(Get.find<FavoritesController>().ids, <int>{4});
    });
  });

  group('Session and start route', () {
    test('a new install goes to sign-in, a signed-in one to the app', () async {
      await setUpScreenDependencies();
      expect(SplashController().nextRoute, AppRoute.auth);
      final SessionStore session = SessionStore(
        Get.find<MyServices>().sharedPreferences,
      );
      await session.signInAsGuest();
      expect(session.isSignedIn, isTrue);
      expect(SplashController().nextRoute, AppRoute.main);
      await session.signOut();
      expect(SplashController().nextRoute, AppRoute.auth);
    });
  });

  group('MainController', () {
    test('starts on Home and opens Explore', () {
      final MainController c = MainController();
      expect(c.tab.value, MainTab.home);
      c.openExplore();
      expect(c.tab.value, MainTab.explore);
    });
  });

  test('greeting follows the time of day', () {
    expect(greetingKey(DateTime(2026)), AppStrings.homeGreetingMorning);
    expect(
      greetingKey(DateTime(2026, 1, 1, 11, 59)),
      AppStrings.homeGreetingMorning,
    );
    expect(
      greetingKey(DateTime(2026, 1, 1, 12)),
      AppStrings.homeGreetingAfternoon,
    );
    expect(
      greetingKey(DateTime(2026, 1, 1, 17, 59)),
      AppStrings.homeGreetingAfternoon,
    );
    expect(
      greetingKey(DateTime(2026, 1, 1, 18)),
      AppStrings.homeGreetingEvening,
    );
  });
}
