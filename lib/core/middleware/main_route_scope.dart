import 'package:get/get.dart';

import '../../controller/explore/explore_controller.dart';
import '../../controller/home/home_controller.dart';
import '../../controller/main/main_controller.dart';
import '../../controller/profile/profile_controller.dart';
import '../../routes.dart';

/// Removes the main shell's permanent controllers when its route is
/// disposed (after sign-out), so the next sign-in starts fresh.
///
/// They are permanent because GetX would otherwise drop them while the
/// route is still being built (see `MainBinding`); disposal is the first
/// point where nothing on screen can read them any more.
class MainRouteScope extends GetMiddleware {
  @override
  void onPageDispose() {
    // Signing in again during the exit animation puts up a new shell that
    // reuses these controllers, so they stay but start over.
    if (Get.currentRoute == AppRoute.main) {
      Get.find<MainController>().select(MainTab.home);
      Get.find<ProfileController>().isSigningOut.value = false;
      return;
    }
    Get
      ..delete<MainController>(force: true)
      ..delete<HomeController>(force: true)
      ..delete<ExploreController>(force: true)
      ..delete<ProfileController>(force: true);
  }
}
