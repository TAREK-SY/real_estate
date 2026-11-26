import 'package:get/get.dart';

import '../../core/services/services.dart';
import '../../core/services/session_store.dart';
import '../../routes.dart';

/// Sign-in screen. Google sign-in is not wired up in this app, so the button
/// starts a guest session; the screen says so before moving on.
class AuthController extends GetxController {
  final RxBool isSigningIn = false.obs;

  Future<void> continueAsGuest() async {
    if (isSigningIn.value) return;
    isSigningIn.value = true;
    try {
      await SessionStore(Get.find<MyServices>().sharedPreferences)
          .signInAsGuest();
    } on Object {
      // Saving only skips this screen on the next launch; a storage failure
      // must not keep the guest out of the app.
    }
    if (isClosed) return;
    await Get.offAllNamed<void>(AppRoute.main);
  }
}
