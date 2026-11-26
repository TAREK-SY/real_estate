import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/auth_screen.dart';
import 'package:real_estate/view/screen/details_screen.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

/// The product fixture re-numbered as the Home grid's listing 11.
String _listing11() {
  final Map<String, dynamic> json = Map<String, dynamic>.of(
    fixture('product') as Map<String, dynamic>,
  );
  json['id'] = 11;
  return jsonEncode(json);
}

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  testWidgets('open a listing, save it, go back, restyle the app, sign out', (
    WidgetTester tester,
  ) async {
    final FakeHomeApi api = FakeHomeApi.standard()
      ..responses['/products/11'] = jsonResponse(_listing11());
    await setUpScreenDependencies(handler: api.handle);
    await SessionStore(Get.find<MyServices>().sharedPreferences)
        .signInAsGuest();
    useSurface(tester, const Size(430, 932));
    await tester.pumpWidget(
      appHarness(pages: routes, initialRoute: AppRoute.main),
    );
    await settleFrames(tester);

    // A recommendation card opens its details.
    await tester.ensureVisible(find.byKey(AppKeys.gridCard(11)));
    await settleFrames(tester);
    await tester.tap(find.text('Listing 11'));
    await settleFrames(tester, frames: 12);
    expect(Get.currentRoute, AppRoute.details);
    expect(find.byType(DetailsScreen), findsOneWidget);
    expect(
      find.text('Knoll Saarinen Executive Conference Chair'),
      findsOneWidget,
    );

    // Saved from the details header, and still saved back on Home.
    await tester.tap(find.byKey(AppKeys.favorite(11)));
    await tester.pump();
    await tester.tap(find.byKey(AppKeys.detailsBack));
    await settleFrames(tester, frames: 12);
    expect(Get.currentRoute, AppRoute.main);
    expect(Get.find<FavoritesController>().isFavorite(11), isTrue);

    // Profile: orange palette, then Arabic, both applied at once.
    await tester.tap(find.byKey(AppKeys.navTab(MainTab.profile.index)));
    await settleFrames(tester);
    await tester.tap(find.byKey(AppKeys.profileColors));
    await settleFrames(tester);
    await tester.tap(find.byKey(AppKeys.choiceOption(PaletteId.orange)));
    await settleFrames(tester);
    expect(Get.find<SettingsController>().palette.value, PaletteId.orange);

    await tester.tap(find.byKey(AppKeys.profileLanguage));
    await settleFrames(tester);
    await tester.tap(find.byKey(AppKeys.choiceOption('ar')));
    await settleFrames(tester, frames: 12);
    final BuildContext shell = tester.element(find.byType(MainScreen));
    expect(Directionality.of(shell), TextDirection.rtl);
    expect(shell.palette.id, PaletteId.orange);

    // Signing out lands on sign-in, still in Arabic and orange.
    await tester.ensureVisible(find.byKey(AppKeys.profileLogout));
    await tester.tap(find.byKey(AppKeys.profileLogout));
    await settleFrames(tester, frames: 20);
    expect(Get.currentRoute, AppRoute.auth);
    expect(
      Directionality.of(tester.element(find.byType(AuthScreen))),
      TextDirection.rtl,
    );
    expect(Get.isRegistered<MainController>(), isFalse);
    expect(Get.find<SettingsController>().palette.value, PaletteId.orange);

    // Signing in again builds a fresh shell on the Home tab.
    await tester.tap(find.byKey(AppKeys.googleSignIn));
    await settleFrames(tester, frames: 20);
    expect(Get.currentRoute, AppRoute.main);
    expect(Get.find<MainController>().tab.value, MainTab.home);
    expect(tester.takeException(), isNull);
  });
}
