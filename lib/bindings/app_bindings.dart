import 'package:get/get.dart';

import '../controller/auth/auth_controller.dart';
import '../controller/auth/splash_controller.dart';
import '../controller/explore/explore_controller.dart';
import '../controller/home/home_controller.dart';
import '../controller/main/main_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() => Get.put<SplashController>(SplashController());
}

class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.put<AuthController>(AuthController());
}

/// The main shell is reached with `offAllNamed`. Its controllers are kept
/// permanent and created only once: GetX deletes the previous route's
/// instances while the new route is being built, which could take a freshly
/// put controller with them.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainController>()) {
      Get.put<MainController>(MainController(), permanent: true);
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(HomeController(), permanent: true);
    }
    if (!Get.isRegistered<ExploreController>()) {
      Get.put<ExploreController>(ExploreController(), permanent: true);
    }
  }
}
