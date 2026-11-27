import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/explore/explore_controller.dart';
import 'package:real_estate/controller/home/home_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';
import 'package:real_estate/controller/profile/profile_controller.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/services/session_store.dart';
import 'package:real_estate/core/shared/app_asset_image.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/routes.dart';
import 'package:real_estate/view/screen/auth_screen.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/view/screen/main/profile_view.dart';
import 'package:real_estate/view/widget/circle_icon_button.dart';
import 'package:real_estate/view/widget/profile/profile_menu_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/details_screens.dart';
import '../helpers/home_api.dart';
import '../widget/screen_harness.dart';

Future<void> _pumpProfile(WidgetTester tester, {String locale = 'en'}) async {
  await setUpScreenDependencies(handler: FakeHomeApi.explore().handle);
  await pumpScreen(
    tester,
    page: () => const MainScreen(),
    binding: ProfileTabBinding(),
    locale: locale,
  );
}

ProfileMenuTile _tile(WidgetTester tester, String label) =>
    tester.widget<ProfileMenuTile>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ProfileMenuTile),
      ),
    );

void main() {
  setUpAll(initScreenTestEnvironment);
  tearDown(() => Get.reset());

  testWidgets('shows the guest, the menu and the disabled account rows', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileView), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    const List<String> disabled = <String>[
      'My Booking',
      'Payments',
      'Notification',
      'Security',
      'Help Center',
      'Invite Friends',
    ];
    for (final String label in disabled) {
      expect(_tile(tester, label).onTap, isNull, reason: label);
    }
    for (final String label in <String>['Language', 'Colors', 'Logout']) {
      expect(_tile(tester, label).onTap, isNotNull, reason: label);
    }
    // Disabled rows have no chevron; the two settings rows do.
    expect(
      find.descendant(
        of: find.byType(ProfileMenuTile),
        matching: find.byWidgetPredicate(
          (Widget w) => w is AppAssetImage && w.assetPath.endsWith('right.svg'),
        ),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('the bell and the photo badge are visibly disabled', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pumpProfile(tester);
    for (final Key key in <Key>[
      AppKeys.profileNotifications,
      AppKeys.profileEditPhoto,
    ]) {
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        reason: '$key',
      );
    }
    handle.dispose();
  });

  testWidgets('Language switches to Arabic at once and remembers it', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);
    await tester.tap(find.byKey(AppKeys.profileLanguage));
    await settleFrames(tester);
    expect(find.byKey(AppKeys.choiceSheet), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.choiceOption('ar')));
    await settleFrames(tester, frames: 12);
    expect(find.byKey(AppKeys.choiceSheet), findsNothing);
    expect(find.text('الملف الشخصي'), findsWidgets);
    final BuildContext context = tester.element(find.byType(ProfileView));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(
      Get.find<MyServices>().sharedPreferences.getString(
        SettingsController.languageKey,
      ),
      'ar',
    );
    // Still on the Profile tab after the rebuild.
    expect(Get.find<MainController>().tab.value, MainTab.profile);
  });

  testWidgets('switching language leaves no English text on any tab', (
    WidgetTester tester,
  ) async {
    Iterable<String> values(Object? node) sync* {
      if (node is Map) {
        for (final Object? v in node.values) {
          yield* values(v);
        }
      } else if (node is String) {
        yield node;
      }
    }

    Set<String> strings(String locale) =>
        values(jsonDecode(File('assets/l10n/$locale.json').readAsStringSync()))
            .toSet();
    final Set<String> englishOnly = strings('en').difference(strings('ar'))
      ..removeWhere((String s) => s.contains('{}'));

    await _pumpProfile(tester);
    // Build every tab in English first, as a user browsing before switching.
    for (final MainTab tab in <MainTab>[MainTab.explore, MainTab.profile]) {
      await tester.tap(find.byKey(AppKeys.navTab(tab.index)));
      await settleFrames(tester);
    }
    await tester.tap(find.byKey(AppKeys.profileLanguage));
    await settleFrames(tester);
    await tester.tap(find.byKey(AppKeys.choiceOption('ar')));
    await settleFrames(tester, frames: 12);

    await tester.tap(find.byKey(AppKeys.navTab(MainTab.explore.index)));
    await settleFrames(tester);
    final List<String> stale = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(MainScreen),
            matching: find.byType(Text, skipOffstage: false),
          ),
        )
        .map((Text t) => t.data ?? '')
        .where(englishOnly.contains)
        .toList();
    expect(stale, isEmpty);
  });

  for (final String locale in <String>['en', 'ar']) {
    testWidgets('each language is named in its own script ($locale)', (
      WidgetTester tester,
    ) async {
      await _pumpProfile(tester, locale: locale);
      await tester.tap(find.byKey(AppKeys.profileLanguage));
      await settleFrames(tester);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
    });
  }

  testWidgets('picking the current language just closes the sheet', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);
    await tester.tap(find.byKey(AppKeys.profileLanguage));
    await settleFrames(tester);
    await tester.tap(find.byKey(AppKeys.choiceOption('en')));
    await settleFrames(tester);
    expect(find.byKey(AppKeys.choiceSheet), findsNothing);
    expect(
      Get.find<MyServices>().sharedPreferences.getString(
        SettingsController.languageKey,
      ),
      isNull,
    );
  });

  testWidgets("the sheet's back button closes it without a change", (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);
    await tester.tap(find.byKey(AppKeys.profileColors));
    await settleFrames(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(AppKeys.choiceSheet),
        matching: find.byType(CircleIconButton),
      ),
    );
    await settleFrames(tester);
    expect(find.byKey(AppKeys.choiceSheet), findsNothing);
    expect(Get.find<SettingsController>().palette.value, PaletteId.original);
  });

  testWidgets('Colors applies a palette at once and remembers it', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester);
    await tester.tap(find.byKey(AppKeys.profileColors));
    await settleFrames(tester);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('New Purple'), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.choiceOption(PaletteId.orange)));
    await settleFrames(tester);
    expect(find.byKey(AppKeys.choiceSheet), findsNothing);
    final BuildContext context = tester.element(find.byType(ProfileView));
    expect(context.palette.id, PaletteId.orange);
    expect(
      Get.find<MyServices>().sharedPreferences.getString(
        SettingsController.paletteKey,
      ),
      'orange',
    );
  });

  testWidgets('the Arabic menu mirrors its chevrons', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(tester, locale: 'ar');
    expect(tester.takeException(), isNull);
    expect(find.text('ضيف'), findsOneWidget);
    final Finder chevron = find
        .byWidgetPredicate(
          (Widget w) => w is AppAssetImage && w.assetPath.endsWith('right.svg'),
        )
        .first;
    expect(tester.widget<AppAssetImage>(chevron).matchTextDirection, isTrue);
    // At the left edge in a right-to-left row.
    expect(tester.getCenter(chevron).dx, lessThan(100));
  });

  testWidgets(
    'Logout ends the session, returns to sign-in and drops the tab state',
    (WidgetTester tester) async {
      await setUpScreenDependencies(handler: FakeHomeApi.explore().handle);
      final SessionStore session = SessionStore(
        Get.find<MyServices>().sharedPreferences,
      );
      await session.signInAsGuest();
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(pages: routes, initialRoute: AppRoute.main),
      );
      await settleFrames(tester);
      Get.find<MainController>().select(MainTab.profile);
      await settleFrames(tester);
      await tester.ensureVisible(find.byKey(AppKeys.profileLogout));
      await tester.tap(find.byKey(AppKeys.profileLogout));
      await settleFrames(tester, frames: 20);

      expect(Get.currentRoute, AppRoute.auth);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(session.isSignedIn, isFalse);
      expect(Get.isRegistered<MainController>(), isFalse);
      expect(Get.isRegistered<HomeController>(), isFalse);
      expect(Get.isRegistered<ExploreController>(), isFalse);
      expect(Get.isRegistered<ProfileController>(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'signing in again before the old shell is gone starts a usable shell',
    (WidgetTester tester) async {
      await setUpScreenDependencies(handler: FakeHomeApi.explore().handle);
      await SessionStore(Get.find<MyServices>().sharedPreferences)
          .signInAsGuest();
      useSurface(tester, const Size(430, 932));
      await tester.pumpWidget(
        appHarness(pages: routes, initialRoute: AppRoute.main),
      );
      await settleFrames(tester);
      Get.find<MainController>().select(MainTab.profile);
      await settleFrames(tester);
      await tester.ensureVisible(find.byKey(AppKeys.profileLogout));
      await tester.tap(find.byKey(AppKeys.profileLogout));
      // The sign-in screen is still sliding in over the old shell.
      await tester.pump();
      expect(Get.currentRoute, AppRoute.auth);
      unawaited(Get.offAllNamed<void>(AppRoute.main));
      await settleFrames(tester, frames: 20);

      expect(Get.currentRoute, AppRoute.main);
      expect(Get.find<MainController>().tab.value, MainTab.home);
      Get.find<MainController>().select(MainTab.profile);
      await settleFrames(tester);
      final ProfileMenuTile logout = tester.widget<ProfileMenuTile>(
        find.byKey(AppKeys.profileLogout),
      );
      expect(logout.onTap, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  test('a storage failure while signing out still leaves', () async {
    Get
      ..testMode = true
      ..put<MyServices>(MyServices()..sharedPreferences = _FailingPrefs());
    addTearDown(() => Get.testMode = false);
    final ProfileController c = ProfileController();
    await c.signOut();
    expect(c.isSigningOut.value, isTrue);
  });
}

class _FailingPrefs extends Fake implements SharedPreferences {
  @override
  Future<bool> remove(String key) =>
      Future<bool>.error(PlatformException(code: 'io'));
}
