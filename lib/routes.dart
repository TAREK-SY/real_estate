import 'package:get/get.dart';

import 'bindings/app_bindings.dart';
import 'core/middleware/main_route_scope.dart';
import 'core/middleware/unknown_route_middleware.dart';
import 'view/screen/auth_screen.dart';
import 'view/screen/details_screen.dart';
import 'view/screen/main/main_screen.dart';
import 'view/screen/not_found_screen.dart';
import 'view/screen/splash_screen.dart';

abstract final class AppRoute {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String main = '/main';
  static const String details = '/details';
  static const String notFound = '/not-found';
}

final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
  GetPage<dynamic>(
    name: AppRoute.splash,
    page: () => const SplashScreen(),
    binding: SplashBinding(),
    // Unknown names are matched to the root by GetX's route tree, so this
    // middleware on '/' is where they can be caught.
    middlewares: <GetMiddleware>[UnknownRouteMiddleware()],
  ),
  GetPage<dynamic>(
    name: AppRoute.auth,
    page: () => const AuthScreen(),
    binding: AuthBinding(),
  ),
  GetPage<dynamic>(
    name: AppRoute.main,
    page: () => const MainScreen(),
    binding: MainBinding(),
    middlewares: <GetMiddleware>[MainRouteScope()],
  ),
  GetPage<dynamic>(
    name: AppRoute.details,
    page: () => const DetailsScreen(),
    binding: DetailsBinding(),
  ),
  GetPage<dynamic>(name: AppRoute.notFound, page: () => const NotFoundScreen()),
];

/// Names of every registered route; read by [UnknownRouteMiddleware].
Set<String> get registeredRouteNames =>
    routes.map((GetPage<dynamic> page) => page.name).toSet();
