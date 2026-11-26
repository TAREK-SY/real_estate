import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/details/details_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/details_screen.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

String _productJson(int id) {
  final Map<String, dynamic> json = Map<String, dynamic>.of(
    fixture('product') as Map<String, dynamic>,
  );
  json['id'] = id;
  return jsonEncode(json);
}

/// The real app opened on the main shell, with listings 1 (featured) and
/// 11 (first result) answerable.
Future<FakeHomeApi> _pumpApp(WidgetTester tester) async {
  final FakeHomeApi api = FakeHomeApi.explore()
    ..responses['/products/1'] = jsonResponse(_productJson(1))
    ..responses['/products/11'] = jsonResponse(_productJson(11));
  await setUpScreenDependencies(handler: api.handle);
  await SessionStore(Get.find<MyServices>().sharedPreferences).signInAsGuest();
  useSurface(tester, const Size(430, 932));
  await tester.pumpWidget(
    appHarness(pages: routes, initialRoute: AppRoute.main),
  );
  await settleFrames(tester);
  return api;
}

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  testWidgets('a featured card opens its listing', (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(AppKeys.featuredCard(1)));
    await settleFrames(tester, frames: 12);
    expect(Get.currentRoute, AppRoute.details);
    expect(find.byType(DetailsScreen), findsOneWidget);
    expect(Get.find<DetailsController>().product.value?.id, 1);
  });

  testWidgets('an Explore list card opens its listing', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(AppKeys.navTab(MainTab.explore.index)));
    await settleFrames(tester);
    final Finder card = find.byKey(AppKeys.listCard(11));
    await tester.ensureVisible(card);
    await settleFrames(tester);
    await tester.tap(card);
    await settleFrames(tester, frames: 12);
    expect(Get.currentRoute, AppRoute.details);
    expect(Get.find<DetailsController>().product.value?.id, 11);
  });

  testWidgets('tapping a card twice opens one copy of the listing', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(AppKeys.featuredCard(1)));
    await tester.pump();
    await tester.tap(find.byKey(AppKeys.featuredCard(1)), warnIfMissed: false);
    await settleFrames(tester, frames: 12);
    expect(find.byType(DetailsScreen), findsOneWidget);
    Get.back<void>();
    await settleFrames(tester, frames: 12);
    expect(Get.currentRoute, AppRoute.main);
  });
}
