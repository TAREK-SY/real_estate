import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/favorites/favorites_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/auth_screen.dart';
import 'package:real_estate/view/screen/splash_screen.dart';
import 'package:real_estate/controller/home/home_controller.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/view/widget/featured_property_card.dart';
import 'package:real_estate/view/widget/property_grid_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/home_api.dart';
import '../helpers/test_doubles.dart';
import '../widget/screen_harness.dart';

Future<void> _pumpMain(
  WidgetTester tester,
  FakeHomeApi api, {
  String locale = 'en',
}) async {
  await setUpScreenDependencies(handler: api.handle);
  await pumpScreen(
    tester,
    page: () => const MainScreen(),
    binding: MainBinding(),
    locale: locale,
  );
}

/// Color of the chip container (the decorated box inside the chip).
Color? _chipColor(WidgetTester tester, String slug) {
  final Container box = tester.widget<Container>(
    find
        .descendant(
          of: find.byKey(AppKeys.categoryChip(slug)),
          matching: find.byType(Container),
        )
        .first,
  );
  return (box.decoration! as BoxDecoration).color;
}

class _FailingPrefs extends Mock implements SharedPreferences {}

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  group('Home', () {
    testWidgets('shows featured cards, chips and the grid from the API', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      expect(find.byType(FeaturedPropertyCard), findsNWidgets(2));
      expect(find.text('Listing 1'), findsOneWidget);
      expect(find.byKey(AppKeys.categoryChip('all')), findsOneWidget);
      expect(find.byKey(AppKeys.categoryChip('beauty')), findsOneWidget);
      expect(find.byType(PropertyGridCard), findsNWidgets(2));
      expect(find.text('Brand 11'), findsOneWidget);
      expect(find.text(r'$1,011'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('a chip selects its category', (WidgetTester tester) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products/category/beauty'] = jsonResponse(
          pageJson(<int>[21]),
        );
      await _pumpMain(tester, api);
      final AppPalette palette = AppPalette.original;
      expect(_chipColor(tester, 'all'), palette.primaryText);
      await tester.tap(find.byKey(AppKeys.categoryChip('beauty')));
      await settleFrames(tester);
      expect(_chipColor(tester, 'beauty'), palette.primaryText);
      expect(_chipColor(tester, 'all'), palette.primaryFaint);
      expect(find.text('Listing 21'), findsOneWidget);
      expect(find.text('Listing 11'), findsNothing);
    });

    testWidgets('the heart saves a favorite', (WidgetTester tester) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      await tester.ensureVisible(find.byKey(AppKeys.favorite(11)));
      await settleFrames(tester);
      await tester.tap(find.byKey(AppKeys.favorite(11)));
      await settleFrames(tester);
      expect(Get.find<FavoritesController>().isFavorite(11), isTrue);
      expect(
        tester.getSemantics(find.byKey(AppKeys.favorite(11))),
        matchesSemantics(
          label: 'Remove Listing 11 from favorites',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('search and See All open the Explore tab', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      final MainController main = Get.find<MainController>();
      for (final Key key in <Key>[
        AppKeys.homeSearch,
        AppKeys.featuredSeeAll,
        AppKeys.recommendationSeeAll,
      ]) {
        main.select(MainTab.home);
        await settleFrames(tester);
        await tester.tap(find.byKey(key));
        await settleFrames(tester);
        expect(main.tab.value, MainTab.explore, reason: '$key');
      }
    });

    testWidgets('the search bar focuses the Explore search field', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      await tester.tap(find.byKey(AppKeys.homeSearch));
      await settleFrames(tester);
      final EditableText field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(AppKeys.exploreSearchField),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('the filter icon opens Explore with the filter sheet', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      await tester.tap(find.byKey(AppKeys.homeFilter));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.explore);
      expect(find.byKey(AppKeys.filterSheet), findsOneWidget);
    });

    testWidgets('the bottom bar switches tabs', (WidgetTester tester) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      await tester.tap(find.byKey(AppKeys.navTab(MainTab.profile.index)));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.profile);
      await tester.tap(find.byKey(AppKeys.navTab(MainTab.home.index)));
      await settleFrames(tester);
      expect(Get.find<MainController>().tab.value, MainTab.home);
    });

    testWidgets('the bell is visibly disabled', (WidgetTester tester) async {
      await _pumpMain(tester, FakeHomeApi.standard());
      expect(
        tester.getSemantics(find.byKey(AppKeys.homeNotifications)),
        matchesSemantics(
          label: 'Notifications (not available yet)',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('a failed grid shows a retry that reloads it', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse('', status: 500);
      await _pumpMain(tester, api);
      expect(find.byKey(AppKeys.retryButton), findsOneWidget);
      api.responses['/products'] = jsonResponse(pageJson(<int>[11]));
      await tester.ensureVisible(find.byKey(AppKeys.retryButton));
      await tester.tap(find.byKey(AppKeys.retryButton));
      await settleFrames(tester);
      expect(find.text('Listing 11'), findsOneWidget);
    });

    testWidgets('long titles stay on one line without overflow', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11]).replaceFirst(
            'Listing 11',
            'An extremely long listing title that cannot fit on a card',
          ),
        );
      await _pumpMain(tester, api, locale: 'ar');
      expect(tester.takeException(), isNull);
      // API titles are Latin: cut at their own end, not with a leading "...".
      final RenderParagraph title = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(AppKeys.gridCard(11)),
          matching: find.textContaining('An extremely long'),
        ),
      );
      expect(title.didExceedMaxLines, isTrue);
      expect(title.textDirection, TextDirection.ltr);
    });

    testWidgets('a short Latin title sits at the start of an Arabic card', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard(), locale: 'ar');
      final Finder title = find.descendant(
        of: find.byKey(AppKeys.gridCard(11)),
        matching: find.text('Listing 11'),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        title,
      );
      final TextBox first = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .first;
      final Rect card = tester.getRect(find.byKey(AppKeys.gridCard(11)));
      expect(
        tester.getTopLeft(title).dx + first.left,
        greaterThan(card.center.dx),
        reason: 'In a right-to-left layout the title belongs on the right.',
      );
    });

    testWidgets('mirrors in Arabic: price after the title, heart at the end', (
      WidgetTester tester,
    ) async {
      await _pumpMain(tester, FakeHomeApi.standard(), locale: 'ar');
      final Rect card = tester.getRect(find.byKey(AppKeys.gridCard(11)));
      final Rect heart = tester.getRect(find.byKey(AppKeys.favorite(11)));
      final Rect price = tester.getRect(find.text(r'$1,011'));
      expect(price.right, greaterThan(heart.right));
      expect(heart.left, lessThan(card.center.dx));
      expect(find.text('ضيف'), findsOneWidget);
    });

    for (final PaletteId id in PaletteId.values) {
      testWidgets('renders with the ${id.name} palette', (
        WidgetTester tester,
      ) async {
        await setUpScreenDependencies(handler: FakeHomeApi.standard().handle);
        await Get.find<SettingsController>().changePalette(id);
        await pumpScreen(
          tester,
          page: () => const MainScreen(),
          binding: MainBinding(),
        );
        expect(tester.takeException(), isNull);
        expect(_chipColor(tester, 'all'), AppPalette.of(id).primaryText);
      });
    }
  });

  group('Auth', () {
    testWidgets('Google starts a guest session, says so, and opens the app', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies(handler: FakeHomeApi.standard().handle);
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          initialRoute: AppRoute.auth,
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.auth,
              page: () => const AuthScreen(),
              binding: AuthBinding(),
            ),
            GetPage<dynamic>(
              name: AppRoute.main,
              page: () => const MainScreen(),
              binding: MainBinding(),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      expect(
        find.textContaining('Your Ideal Home', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byKey(AppKeys.googleSignIn));
      await settleFrames(tester, frames: 20);
      expect(find.textContaining('browsing as a guest'), findsOneWidget);
      expect(Get.currentRoute, AppRoute.main);
      expect(find.byType(MainScreen), findsOneWidget);
      expect(
        SessionStore(Get.find<MyServices>().sharedPreferences).isSignedIn,
        isTrue,
      );
    });
  });

  group('Auth storage', () {
    testWidgets('a session that cannot be saved still enters the app', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies(handler: FakeHomeApi.standard().handle);
      final _FailingPrefs prefs = _FailingPrefs();
      when(() => prefs.setBool(any(), any())).thenThrow(Exception('disk full'));
      Get.find<MyServices>().sharedPreferences = prefs;
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          initialRoute: AppRoute.auth,
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.auth,
              page: () => const AuthScreen(),
              binding: AuthBinding(),
            ),
            GetPage<dynamic>(
              name: AppRoute.main,
              page: () => const MainScreen(),
              binding: MainBinding(),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      await tester.tap(find.byKey(AppKeys.googleSignIn));
      await settleFrames(tester, frames: 20);
      expect(Get.currentRoute, AppRoute.main);
    });
  });

  group('Splash', () {
    testWidgets('moves on to sign-in after the delay', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies();
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(
          pages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoute.splash,
              page: () => const SplashScreen(),
              binding: SplashBinding(),
            ),
            GetPage<dynamic>(
              name: AppRoute.auth,
              page: () => const Scaffold(body: Text('sign-in')),
            ),
          ],
        ),
      );
      await settleFrames(tester);
      expect(find.text('sign-in'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1600));
      await settleFrames(tester);
      expect(find.text('sign-in'), findsOneWidget);
    });
  });

  group('Home extras', () {
    testWidgets('a listing without a brand shows its category', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11]).replaceFirst('"brand":"Brand 11",', ''),
        );
      await _pumpMain(tester, api);
      expect(
        find.descendant(
          of: find.byKey(AppKeys.gridCard(11)),
          matching: find.text('Furniture'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('scrolling near the end loads the next page', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11, 12], total: 3),
        )
        ..responses['/products?skip=10'] = jsonResponse(
          pageJson(<int>[13], total: 3, skip: 10),
        );
      await _pumpMain(tester, api);
      await tester.drag(find.byKey(AppKeys.homeScroll), const Offset(0, -600));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.gridCard(13)), findsOneWidget);
    });

    testWidgets('each grid card is its own screen reader item', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpMain(tester, FakeHomeApi.standard());
      final List<String> labels = <String>[];
      void collect(SemanticsNode node) {
        labels.add(node.label);
        node.visitChildren((SemanticsNode child) {
          collect(child);
          return true;
        });
      }

      collect(tester.getSemantics(find.byKey(AppKeys.gridCard(11))));
      final String label = labels.join(' ');
      expect(label, contains('Listing 11'));
      expect(label, isNot(contains('Listing 12')));
      semantics.dispose();
    });

    testWidgets('a failed next page shows a retry row that loads it', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products'] = jsonResponse(
          pageJson(<int>[11, 12], total: 3),
        )
        ..responses['/products?skip=10'] = jsonResponse('', status: 500);
      await _pumpMain(tester, api);
      await tester.drag(find.byKey(AppKeys.homeScroll), const Offset(0, -600));
      await settleFrames(tester);
      await tester.drag(find.byKey(AppKeys.homeScroll), const Offset(0, -600));
      await settleFrames(tester);
      expect(
        api.requests.where((Uri u) => u.queryParameters['skip'] == '10'),
        hasLength(1),
      );
      api.responses['/products?skip=10'] = jsonResponse(
        pageJson(<int>[13], total: 3, skip: 10),
      );
      await tester.ensureVisible(find.byKey(AppKeys.retryButton));
      await settleFrames(tester);
      await tester.tap(find.byKey(AppKeys.retryButton));
      await settleFrames(tester);
      expect(find.byKey(AppKeys.gridCard(13)), findsOneWidget);
      expect(find.byKey(AppKeys.retryButton), findsNothing);
    });

    testWidgets('pull to refresh reloads every section', (
      WidgetTester tester,
    ) async {
      final FakeHomeApi api = FakeHomeApi.standard()
        ..responses['/products/categories'] = jsonResponse('', status: 500);
      await _pumpMain(tester, api);
      api.responses['/products/categories'] = jsonResponse(
        fixtureText('categories'),
      );
      await Get.find<HomeController>().refreshAll();
      await settleFrames(tester);
      expect(find.byKey(AppKeys.categoryChip('beauty')), findsOneWidget);
    });
  });
}
