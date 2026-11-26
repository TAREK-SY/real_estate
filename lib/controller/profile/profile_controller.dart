import 'dart:developer' as developer;

import 'package:get/get.dart';

import '../../core/services/services.dart';
import '../../core/services/session_store.dart';
import '../../routes.dart';

/// Profile tab. The language and palette are changed through
/// `SettingsController`; this ends the guest session.
class ProfileController extends GetxController {
  final RxBool isSigningOut = false.obs;

  Future<void> signOut() async {
    if (isSigningOut.value) return;
    isSigningOut.value = true;
    try {
      await SessionStore(Get.find<MyServices>().sharedPreferences).signOut();
    } on Exception catch (e, st) {
      // Leaving must not fail on storage; at worst the next launch skips
      // the sign-in screen once.
      developer.log(
        'could not clear the session',
        name: 'Profile',
        error: e,
        stackTrace: st,
      );
    }
    // The tab controllers go with the main route itself (MainRouteScope),
    // once it is off screen.
    await Get.offAllNamed<void>(AppRoute.auth);
  }
}
