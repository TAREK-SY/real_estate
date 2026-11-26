import 'package:get/get.dart';

import 'core/middleware/unknown_route_middleware.dart';
import 'view/screen/not_found_screen.dart';
import 'view/screen/splash_screen.dart';

abstract final class AppRoute {
  static const String splash = '/';
  static const String notFound = '/not-found';
}

final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
  GetPage<dynamic>(
    name: AppRoute.splash,
    page: () => const SplashScreen(),
    // Unknown names are matched to the root by GetX's route tree, so this
    // middleware on '/' is where they can be caught.
    middlewares: <GetMiddleware>[UnknownRouteMiddleware()],
  ),
  GetPage<dynamic>(name: AppRoute.notFound, page: () => const NotFoundScreen()),
];

/// Names of every registered route; read by [UnknownRouteMiddleware].
Set<String> get registeredRouteNames =>
    routes.map((GetPage<dynamic> page) => page.name).toSet();
