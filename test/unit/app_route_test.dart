import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' show Widget;
import 'package:real_estate/core/middleware/unknown_route_middleware.dart';
import 'package:real_estate/routes.dart';

/// Every AppRoute constant. Updated by hand on purpose: adding a route
/// without listing it here fails the test.
const List<String> _allRoutes = <String>[AppRoute.splash, AppRoute.notFound];

void main() {
  group('AppRoute', () {
    test('names are unique, absolute and without spaces', () {
      expect(_allRoutes.toSet(), hasLength(_allRoutes.length));
      for (final String route in _allRoutes) {
        expect(route.startsWith('/'), isTrue, reason: route);
        expect(route.contains(' '), isFalse, reason: route);
      }
    });

    test('every constant is registered, and nothing else', () {
      expect(registeredRouteNames, _allRoutes.toSet());
    });

    test('each route builds its screen', () {
      for (final GetPage<dynamic> page in routes) {
        expect(page.page(), isA<Widget>(), reason: page.name);
      }
    });

    test('the root carries the unknown-route middleware', () {
      final GetPage<dynamic> root = routes.firstWhere(
        (GetPage<dynamic> p) => p.name == AppRoute.splash,
      );
      expect(
        root.middlewares?.whereType<UnknownRouteMiddleware>(),
        hasLength(1),
      );
    });
  });

  group('UnknownRouteMiddleware', () {
    final UnknownRouteMiddleware middleware = UnknownRouteMiddleware();

    test('runs first', () => expect(middleware.priority, 0));

    test('lets registered routes through, with or without a query', () {
      expect(middleware.redirect(AppRoute.splash), isNull);
      expect(middleware.redirect('${AppRoute.notFound}?x=1'), isNull);
    });

    test('ignores empty names', () {
      expect(middleware.redirect(null), isNull);
      expect(middleware.redirect(''), isNull);
    });

    test('sends unknown names to the not-found route', () {
      expect(middleware.redirect('/nope')?.name, AppRoute.notFound);
      expect(middleware.redirect('/products/1')?.name, AppRoute.notFound);
    });
  });
}
