import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/class/handling_data_view.dart';
import 'package:real_estate/core/class/status_request.dart';
import 'package:real_estate/view/screen/not_found_screen.dart';
import 'package:real_estate/view/screen/splash_screen.dart';

import '../helpers/screen_sizes.dart';
import '../widget/screen_harness.dart';

/// Tap-target size, labels and text contrast on the stage's screens and
/// shared state views, in both languages.
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'SplashScreen': () => const SplashScreen(),
  'NotFoundScreen': () => const NotFoundScreen(),
  'ErrorStateView': () => Scaffold(
    body: HandlingDataView(
      status: StatusRequest.serverFailure,
      onRetry: () {},
      child: const SizedBox.shrink(),
    ),
  ),
};

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  for (final MapEntry<String, Widget Function()>(key: name, value: page)
      in _screens.entries) {
    for (final String locale in testLocales) {
      testWidgets('$name meets accessibility guidelines ($locale)', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpScreen(tester, page: page, locale: locale);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
