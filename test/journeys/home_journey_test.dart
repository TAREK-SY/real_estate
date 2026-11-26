import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  testWidgets(
    'first launch: splash, sign-in, home, category, favorite, explore',
    (WidgetTester tester) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21, 22]),
        );
      await setUpScreenDependencies(handler: api.handle);
      useSurface(tester, const Size(430, 932));
      // The app's own route table, so bindings and middlewares are real.
      await tester.pumpWidget(appHarness(pages: routes));
      await settleFrames(tester);

      // Splash hands over to sign-in on a fresh install.
      await tester.pump(const Duration(milliseconds: 1600));
      await settleFrames(tester);
      expect(Get.currentRoute, AppRoute.auth);

      await tester.tap(find.byKey(AppKeys.googleSignIn));
      await settleFrames(tester, frames: 20);
      expect(Get.currentRoute, AppRoute.main);
      expect(find.byType(MainScreen), findsOneWidget);
      expect(
        SessionStore(Get.find<MyServices>().sharedPreferences).isSignedIn,
        isTrue,
      );
      expect(find.byKey(AppKeys.gridCard(11)), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.categoryChip('beauty')));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.gridCard(21)), findsOneWidget);
      expect(find.byKey(AppKeys.gridCard(11)), findsNothing);

      // Let the guest notice leave the bottom of the screen first.
      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(find.byKey(AppKeys.favorite(21)));
      await settleFrames(tester);
      await tester.tap(find.byKey(AppKeys.favorite(21)));
      await settleFrames(tester);
      expect(Get.find<FavoritesController>().isFavorite(21), isTrue);

      await tester.tap(find.byKey(AppKeys.navTab(MainTab.explore.index)));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.explore);
    },
  );

  testWidgets('a returning guest goes from splash straight to home', (
    WidgetTester tester,
  ) async {
    await setUpScreenDependencies(handler: FakeHomeApi.standard().handle);
    await SessionStore(Get.find<MyServices>().sharedPreferences)
        .signInAsGuest();
    useSurface(tester, const Size(430, 932));
    await tester.pumpWidget(appHarness(pages: routes));
    await settleFrames(tester);
    await tester.pump(const Duration(milliseconds: 1600));
    await settleFrames(tester);
    expect(Get.currentRoute, AppRoute.main);
    expect(find.byKey(AppKeys.gridCard(11)), findsOneWidget);
  });
}
