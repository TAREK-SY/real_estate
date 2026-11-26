import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/explore/explore_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/localization/app_strings.dart';
import 'package:real_estate/core/shared/ltr_text.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/data/model/product_filter.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/view/widget/filter/app_range_slider.dart';
import 'package:real_estate/view/widget/property_grid_card.dart';
import 'package:real_estate/view/widget/property_list_card.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<ExploreController> _pumpExplore(
  WidgetTester tester,
  FakeHomeApi api, {
  String locale = 'en',
  Size size = const Size(430, 932),
}) async {
  await setUpScreenDependencies(handler: api.handle);
  await pumpScreen(
    tester,
    page: () => const MainScreen(),
    binding: MainBinding(),
    locale: locale,
    size: size,
  );
  Get.find<MainController>().select(MainTab.explore);
  await settleFrames(tester);
  return Get.find<ExploreController>();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(AppKeys.exploreFilter));
  await settleFrames(tester);
}

Color? _chipColor(WidgetTester tester, Key key) {
  final Container box = tester.widget<Container>(
    find
        .descendant(of: find.byKey(key), matching: find.byType(Container))
        .first,
  );
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  group('Explore', () {
    testWidgets('lists the results with their count, then as a grid', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      expect(find.text('Search for Your Ideal Home'), findsOneWidget);
      expect(find.byType(PropertyListCard), findsNWidgets(2));
      expect(find.text('Found 2 results'), findsOneWidget);
      expect(find.bySemanticsLabel('Show as grid'), findsOneWidget);

      await tester.tap(find.byKey(AppKeys.exploreLayoutToggle));
      await settleFrames(tester);
      expect(find.byType(PropertyListCard), findsNothing);
      expect(find.byType(PropertyGridCard), findsNWidgets(2));
      expect(find.bySemanticsLabel('Show as list'), findsOneWidget);
    });

    testWidgets('counts in Arabic plural forms', (WidgetTester tester) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
        locale: 'ar',
      );
      final Map<int, String> forms = <int, String>{
        0: 'لا نتائج',
        1: 'نتيجة واحدة',
        2: 'نتيجتان',
        3: '3 نتائج',
        11: '11 نتيجة',
        100: '100 نتيجة',
      };
      for (final MapEntry<int, String>(key: int n, value: String text)
          in forms.entries) {
        c.results.total.value = n;
        await tester.pump();
        expect(find.text(text), findsOneWidget, reason: '$n');
      }
    });

    testWidgets('a failure offers a retry that reloads', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products'] = jsonResponse('', status: 500);
      await _pumpExplore(tester, api);
      expect(find.byKey(AppKeys.retryButton), findsWidgets);
      api.responses['/products'] = jsonResponse(pageJson(<int>[11, 12]));
      await tester.tap(find.byKey(AppKeys.retryButton).last);
      await settleFrames(tester);
      expect(find.byType(PropertyListCard), findsNWidgets(2));
    });

    testWidgets('no match says so', (WidgetTester tester) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/search?q=zzz'] = jsonResponse(pageJson(<int>[]));
      await _pumpExplore(tester, api);
      await tester.enterText(find.byKey(AppKeys.exploreSearchField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settleFrames(tester);
      expect(
        find.text(AppStrings.t(AppStrings.exploreNoResults)),
        findsOneWidget,
      );
      expect(find.text('Found 0 results'), findsOneWidget);
    });

    testWidgets('a chip selects its category', (WidgetTester tester) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        );
      await _pumpExplore(tester, api);
      await tester.tap(find.byKey(AppKeys.categoryChip('beauty')).last);
      await settleFrames(tester);
      expect(find.byKey(AppKeys.listCard(21)), findsOneWidget);
      expect(
        _chipColor(tester, AppKeys.categoryChip('beauty')),
        AppPalette.original.primaryText,
      );
    });

    testWidgets('back returns to Home; the bell is visibly disabled', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      expect(
        tester.getSemantics(find.byKey(AppKeys.exploreNotifications)),
        matchesSemantics(
          label: 'Notifications (not available yet)',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      await tester.tap(find.byKey(AppKeys.exploreBack));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.home);
    });

    testWidgets('the system back button returns to Home, then leaves', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      await tester.binding.handlePopRoute();
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.home);
      final PopScope<Object?> scope = tester.widget(
        find.byType(PopScope<Object?>),
      );
      expect(scope.canPop, isTrue, reason: 'Home lets the app close');
    });

    testWidgets('a photo that fails to load leaves the card intact', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      await settleFrames(tester, frames: 12);
      expect(tester.takeException(), isNull);
      final Finder card = find.byKey(AppKeys.listCard(11));
      expect(
        tester.getSemantics(card).label,
        startsWith('Image unavailable\n'),
      );
      expect(
        tester.getSize(card).height,
        moreOrLessEquals(128, epsilon: 0.5),
        reason: '100 photo box plus 14 padding above and below',
      );
    });

    testWidgets('mirrors in Arabic: photo at the start, price at the end', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore(), locale: 'ar');
      final Rect card = tester.getRect(find.byKey(AppKeys.listCard(11)));
      final Rect price = tester.getRect(find.text(r'$1,011'));
      final Rect title = tester.getRect(find.text('Listing 11'));
      expect(title.right, greaterThan(price.right));
      expect(price.left, lessThan(card.center.dx));
      expect(title.right, greaterThan(card.center.dx));
    });

    testWidgets('a long title wraps to two lines inside the card', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products'] = jsonResponse(
          listingsJson(<Map<String, Object>>[
            listing(1, category: 'beauty', price: 36999.99)
              ..['title'] =
                  'An extremely long listing title that keeps on going far '
                  'beyond what any card could ever show on one line',
          ]),
        );
      await _pumpExplore(tester, api, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final Rect card = tester.getRect(find.byKey(AppKeys.listCard(1)));
      final Rect price = tester.getRect(find.text(r'$36,999.99'));
      expect(card.contains(price.topLeft), isTrue);
      expect(card.contains(price.bottomRight), isTrue);
    });

    testWidgets('scrolling near the end loads the next page', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.explore()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[for (int i = 1; i <= 10; i++) i], total: 12),
        )
        ..responses['/products?skip=10'] = jsonResponse(
          pageJson(<int>[11, 12], skip: 10, total: 12),
        )
        ..holds['/products?skip=10'] = Completer<void>();
      await _pumpExplore(tester, api);
      await tester.drag(
        find.byKey(AppKeys.exploreScroll),
        const Offset(0, -1200),
      );
      await tester.pump();
      expect(find.byKey(AppKeys.loadingView), findsOneWidget);
      api.holds['/products?skip=10']!.complete();
      await settleFrames(tester);
      await tester.drag(
        find.byKey(AppKeys.exploreScroll),
        const Offset(0, -2000),
      );
      await settleFrames(tester);
      expect(find.byKey(AppKeys.listCard(12)), findsOneWidget);
    });

    for (final PaletteId id in PaletteId.values) {
      testWidgets('renders with the ${id.name} palette', (
        WidgetTester tester,
      ) async {
        await setUpScreenDependencies(handler: FakeHomeApi.explore().handle);
        await Get.find<SettingsController>().changePalette(id);
        await pumpScreen(
          tester,
          page: () => const MainScreen(),
          binding: MainBinding(),
        );
        Get.find<MainController>().select(MainTab.explore);
        await settleFrames(tester);
        expect(tester.takeException(), isNull);
        expect(
          _chipColor(tester, AppKeys.categoryChip('all')),
          AppPalette.of(id).primaryText,
        );
      });
    }
  });

  group('Filter sheet', () {
    testWidgets('shows every section with the spans of the data', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      await _openSheet(tester);
      for (final String key in <String>[
        AppStrings.filterTitle,
        AppStrings.filterPrice,
        AppStrings.filterType,
        AppStrings.filterDetails,
        AppStrings.filterWeight,
      ]) {
        expect(find.text(AppStrings.t(key)), findsOneWidget, reason: key);
      }
      expect(find.text(r'$5.99'), findsOneWidget);
      expect(find.text(r'$1,500'), findsOneWidget);
      expect(find.byKey(AppKeys.filterType('beauty')), findsOneWidget);
    });

    testWidgets('steppers count within their limits', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      await _openSheet(tester);
      final Key minus = AppKeys.stepperMinus(AppKeys.filterRatingStepper);
      final Key plus = AppKeys.stepperPlus(AppKeys.filterRatingStepper);
      await tester.ensureVisible(find.byKey(AppKeys.filterStockStepper));
      await tester.pump();
      expect(
        tester.getSemantics(find.byKey(minus)),
        matchesSemantics(
          label: 'Decrease Min. rating',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.byKey(plus));
        await tester.pump();
      }
      expect(c.draft.value.minRating, 5);
      await tester.tap(find.byKey(minus));
      await tester.pump();
      expect(c.draft.value.minRating, 4);

      await tester.tap(
        find.byKey(AppKeys.stepperPlus(AppKeys.filterStockStepper)),
      );
      await tester.pump();
      expect(c.draft.value.minStock, 10);
      expect(c.filter.value, ProductFilter.none, reason: 'not applied yet');
    });

    testWidgets('Set Filter applies the draft and closes', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      await _openSheet(tester);
      await tester.tap(find.byKey(AppKeys.filterType('furniture')));
      await tester.pump();
      expect(
        _chipColor(tester, AppKeys.filterType('furniture')),
        AppPalette.original.primaryText,
      );
      await tester.ensureVisible(find.byKey(AppKeys.filterType('smartphones')));
      await tester.tap(find.byKey(AppKeys.filterType('smartphones')));
      await tester.tap(find.byKey(AppKeys.filterApply));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.filterSheet), findsNothing);
      expect(c.filter.value.categories, <String>{'furniture', 'smartphones'});
      expect(find.text('Found 3 results'), findsOneWidget);
      expect(find.byKey(AppKeys.listCard(6)), findsOneWidget);
    });

    testWidgets('Reset clears the draft; back closes without applying', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      await _openSheet(tester);
      await tester.tap(find.byKey(AppKeys.filterType('beauty')));
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.filterReset));
      await tester.pump();
      expect(c.draft.value, ProductFilter.none);

      await tester.tap(find.byKey(AppKeys.filterType('beauty')));
      await tester.tap(find.byKey(AppKeys.filterClose));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.filterSheet), findsNothing);
      expect(c.filter.value, ProductFilter.none);
    });

    testWidgets('dragging the price thumb sets a price range', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      await _openSheet(tester);
      final Rect slider = tester.getRect(find.byKey(AppKeys.filterPriceSlider));
      final Offset start = Offset(
        slider.left + 1,
        slider.top + AppRangeSlider.sliderHeight / 2,
      );
      await tester.dragFrom(start, Offset(slider.width / 2, 0));
      await tester.pump();
      expect(c.draft.value.price, isNotNull);
      expect(c.draft.value.price!.start, greaterThan(5.99));
    });

    for (final String locale in <String>['en', 'ar']) {
      testWidgets('price labels stay inside the slider at full range '
          '($locale)', (WidgetTester tester) async {
        await _pumpExplore(tester, FakeHomeApi.explore(), locale: locale);
        await _openSheet(tester);
        final Finder slider = find.byKey(AppKeys.filterPriceSlider);
        final Rect box = tester.getRect(slider);
        final Finder labels = find.descendant(
          of: slider,
          matching: find.byType(LtrText),
        );
        expect(labels, findsNWidgets(2));
        for (int i = 0; i < 2; i++) {
          final Rect label = tester.getRect(labels.at(i));
          expect(label.left, greaterThanOrEqualTo(box.left));
          expect(label.right, lessThanOrEqualTo(box.right));
        }
      });
    }

    testWidgets('dragging the weight thumb sets a weight range', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      await _openSheet(tester);
      final Finder weight = find.byKey(AppKeys.filterWeightSlider);
      await tester.ensureVisible(weight);
      await tester.pump();
      expect(find.text('1'), findsWidgets);
      expect(find.text('10'), findsOneWidget);
      final Rect slider = tester.getRect(weight);
      await tester.dragFrom(
        Offset(slider.right - 1, slider.top + AppRangeSlider.sliderHeight / 2),
        Offset(-slider.width / 2, 0),
      );
      await tester.pump();
      expect(c.draft.value.weight, isNotNull);
      expect(c.draft.value.weight!.end, lessThan(10));
    });

    testWidgets('spans that fail to load offer a retry', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products?all'] = jsonResponse('', status: 500);
      await _pumpExplore(tester, api);
      await _openSheet(tester);
      expect(find.byKey(AppKeys.filterPriceSlider), findsNothing);
      expect(find.text(AppStrings.t(AppStrings.filterWeight)), findsNothing);
      api.responses['/products?all'] = jsonResponse(
        listingsJson(exploreListings),
      );
      await tester.tap(find.byKey(AppKeys.retryButton).last);
      await settleFrames(tester);
      expect(find.byKey(AppKeys.filterPriceSlider), findsOneWidget);
    });

    testWidgets('ranges kept from an earlier search fit the new spans', (
      WidgetTester tester,
    ) async {
      final ExploreController c = await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
      );
      c.filter.value = ProductFilter.none
          .withPrice(const ValueRange(2000, 3000))
          .withWeight(const ValueRange(20, 40));
      await _openSheet(tester);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(AppKeys.filterWeightSlider));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      expect(find.text(r'$1,500'), findsOneWidget);
    });

    testWidgets('Set Filter spans the content width', (
      WidgetTester tester,
    ) async {
      await _pumpExplore(tester, FakeHomeApi.explore());
      await _openSheet(tester);
      expect(
        tester.getSize(find.byKey(AppKeys.filterApply)).width,
        moreOrLessEquals(390, epsilon: 0.5),
      );
    });

    testWidgets('fits a small phone in Arabic', (WidgetTester tester) async {
      await _pumpExplore(
        tester,
        FakeHomeApi.explore(),
        locale: 'ar',
        size: const Size(320, 568),
      );
      await _openSheet(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('تطبيق الفلاتر'), findsOneWidget);
    });
  });
}
