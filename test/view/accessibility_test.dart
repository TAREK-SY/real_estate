import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/class/handling_data_view.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/view/screen/not_found_screen.dart';
import 'package:real_estate/view/screen/splash_screen.dart';
import 'package:real_estate/view/screen/auth_screen.dart';
import 'package:real_estate/view/screen/details_screen.dart';
import 'package:real_estate/view/screen/main/main_screen.dart';
import 'package:real_estate/bindings/app_bindings.dart';

import '../helpers/details_screens.dart';
import '../helpers/explore_screens.dart';

import '../helpers/screen_sizes.dart';
import '../widget/screen_harness.dart';

/// Tap-target size, labels and text contrast on the stage's screens and
/// shared state views, in both languages.
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'SplashScreen': () => const SplashScreen(),
  'NotFoundScreen': () => const NotFoundScreen(),
  'AuthScreen': () => const AuthScreen(),
  'MainScreen': () => const MainScreen(),
  for (final String name in exploreScreens.keys) name: () => const MainScreen(),
  'DetailsScreen': () => const DetailsScreen(),
  'ProfileTab': () => const MainScreen(),
  'ErrorStateView': () => Scaffold(
    body: HandlingDataView(
      status: StatusRequest.serverFailure,
      onRetry: () {},
      child: const SizedBox.shrink(),
    ),
  ),
};

final Map<String, Bindings> _bindings = <String, Bindings>{
  'AuthScreen': AuthBinding(),
  'MainScreen': MainBinding(),
  for (final MapEntry<String, Bindings Function()>(
        :String key,
        :Bindings Function() value,
      )
      in exploreScreens.entries)
    key: value(),
  'DetailsScreen': DetailsTestBinding(),
  'ProfileTab': ProfileTabBinding(),
};

/// Screens with text in a horizontal list nested in a vertical one. The
/// contrast guideline samples those labels at the wrong place on screen
/// (changing the search hint color changes the result for the third chip),
/// so for them it is replaced by `palette_contrast_test.dart`.
/// The Explore states are the same shell with the same chips (the filter
/// sheet's chips sit over the dimmed shell, which the sampling also picks up).
const Set<String> _contrastSampledWrongly = <String>{
  'MainScreen',
  'ExploreList',
  'ExploreGrid',
  'FilterSheet',
};

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(() => setUpScreenDependencies(handler: detailsApi().handle));

  for (final MapEntry<String, Widget Function()>(key: name, value: page)
      in _screens.entries) {
    for (final String locale in testLocales) {
      testWidgets('$name meets accessibility guidelines ($locale)', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          page: page,
          binding: _bindings[name],
          locale: locale,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        if (!_contrastSampledWrongly.contains(name)) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      });
    }
  }
}
