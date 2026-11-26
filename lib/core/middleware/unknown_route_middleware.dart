import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../routes.dart';

/// Sends any unregistered route name to [AppRoute.notFound].
///
/// `GetMaterialApp.unknownRoute` never fires: GetX's route tree matches
/// unknown names to '/', so this middleware sits on '/' and checks the
/// requested name itself.
class UnknownRouteMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    if (route == null || route.isEmpty) return null;
    final String path = Uri.tryParse(route)?.path ?? route;
    if (path.isEmpty) return null;
    // Read on each call: `routes` builds this object, so reading it in a
    // field initializer would be circular.
    if (registeredRouteNames.contains(path)) return null;
    return const RouteSettings(name: AppRoute.notFound);
  }
}
