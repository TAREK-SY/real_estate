import 'package:get/get.dart';

import '../../core/services/services.dart';
import '../../core/services/session_store.dart';
import '../../routes.dart';

/// Shows the splash for a moment, then opens the app or the sign-in screen.
class SplashController extends GetxController {
  SplashController({this.delay = defaultDelay});

  static const Duration defaultDelay = Duration(milliseconds: 1500);

  final Duration delay;

  String get nextRoute =>
      SessionStore(Get.find<MyServices>().sharedPreferences).isSignedIn
      ? AppRoute.main
      : AppRoute.auth;

  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(delay, () {
      if (isClosed) return;
      Get.offAllNamed<void>(nextRoute);
    });
  }
}
