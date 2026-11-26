import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/explore/explore_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/view/widget/filter/app_range_slider.dart';
import 'package:real_estate/view/widget/property_grid_card.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  testWidgets(
    'search from Home, pick a category, cap the price, switch to a grid',
    (WidgetTester tester) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=a'] = jsonResponse(
          listingsJson(exploreListings),
        )
        ..responses['/products/search?q=a&all'] = jsonResponse(
          listingsJson(exploreListings),
        );
      await setUpScreenDependencies(handler: api.handle);
      await pumpScreen(
        tester,
        page: () => const MainScreen(),
        binding: MainBinding(),
      );

      // Home's search bar opens Explore with the field focused.
      await tester.tap(find.byKey(AppKeys.homeSearch));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.explore);
      await tester.enterText(find.byKey(AppKeys.exploreSearchField), 'a');
      await tester.pump(ExploreController.searchDebounce);
      await settleFrames(tester);
      expect(find.text('Found 6 results'), findsOneWidget);

      // A category with a search is narrowed on the device.
      await tester.tap(find.byKey(AppKeys.categoryChip('furniture')).last);
      await settleFrames(tester);
      expect(find.text('Found 2 results'), findsOneWidget);
      expect(find.byKey(AppKeys.listCard(3)), findsOneWidget);
      expect(find.byKey(AppKeys.listCard(5)), findsOneWidget);

      // Lower the top price: the $299.99 sofa drops out, the $89 one stays.
      await tester.tap(find.byKey(AppKeys.exploreFilter));
      await settleFrames(tester);
      final Rect slider = tester.getRect(find.byKey(AppKeys.filterPriceSlider));
      await tester.dragFrom(
        Offset(slider.right - 1, slider.top + AppRangeSlider.sliderHeight / 2),
        Offset(-slider.width * 0.4, 0),
      );
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.filterApply));
      await settleFrames(tester);
      expect(find.text('Found 1 result'), findsOneWidget);
      expect(find.byKey(AppKeys.listCard(5)), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.exploreLayoutToggle));
      await settleFrames(tester);
      expect(find.byType(PropertyGridCard), findsOneWidget);
    },
  );
}
