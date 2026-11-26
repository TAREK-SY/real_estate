import 'package:easy_localization/easy_localization.dart' show EasyLocalization;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/localization/app_strings.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screen_harness.dart';

/// Shows the current palette, direction and a translated string, and offers
/// the two settings actions, so the test sees what a real screen would.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = Get.find<SettingsController>();
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text('primary:${context.palette.primary.toARGB32()}'),
          Text('dir:${Directionality.of(context).name}'),
          Text(AppStrings.t(AppStrings.stateRetry)),
          TextButton(
            onPressed: () => settings.changeLanguage(context, 'ar'),
            child: const Text('to-ar'),
          ),
          TextButton(
            onPressed: () => settings.changePalette(PaletteId.orange),
            child: const Text('to-orange'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  testWidgets('changing the palette recolors the app immediately', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    expect(find.text('primary:${0xFF0061FF}'), findsOneWidget);

    await tester.tap(find.text('to-orange'));
    await settleFrames(tester);

    expect(find.text('primary:${0xFFFF8000}'), findsOneWidget);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsController.paletteKey), 'orange');
  });

  testWidgets('a locale set through easy_localization alone still applies', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    final BuildContext context = tester.element(find.byType(_Probe));
    await EasyLocalization.of(context)!.setLocale(const Locale('ar'));
    await settleFrames(tester, frames: 12);
    expect(find.text('dir:rtl'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('the app registers the Material and Cupertino delegates', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    final GetMaterialApp app = tester.widget<GetMaterialApp>(
      find.byType(GetMaterialApp),
    );
    expect(
      app.localizationsDelegates,
      containsAll(GlobalMaterialLocalizations.delegates),
    );
  });

  testWidgets('text selection uses the palette color', (
    WidgetTester tester,
  ) async {
    await setUpScreenDependencies(
      prefs: <String, Object>{SettingsController.paletteKey: 'orange'},
    );
    await pumpScreen(tester, page: () => const _Probe());
    final ThemeData theme = Theme.of(tester.element(find.byType(_Probe)));
    expect(
      theme.textSelectionTheme.selectionColor?.toARGB32(),
      AppPalette.orange.primary.withValues(alpha: 0.4).toARGB32(),
    );
  });

  testWidgets('a saved palette is applied on start', (
    WidgetTester tester,
  ) async {
    await setUpScreenDependencies(
      prefs: <String, Object>{SettingsController.paletteKey: 'purple'},
    );
    await pumpScreen(tester, page: () => const _Probe());
    expect(find.text('primary:${0xFF8B5DFF}'), findsOneWidget);
  });

  testWidgets('switching to Arabic flips direction and text without restart', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    expect(find.text('dir:ltr'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('to-ar'));
    await settleFrames(tester, frames: 12);

    expect(find.text('dir:rtl'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(Get.locale, const Locale('ar'));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsController.languageKey), 'ar');
  });

  testWidgets('an unsupported language code is ignored', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    final BuildContext context = tester.element(find.byType(_Probe));
    await Get.find<SettingsController>().changeLanguage(context, 'fr');
    await settleFrames(tester);
    expect(find.text('dir:ltr'), findsOneWidget);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsController.languageKey), isNull);
  });

  testWidgets('choosing the active palette again writes nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const _Probe());
    await Get.find<SettingsController>().changePalette(PaletteId.original);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsController.paletteKey), isNull);
  });
}
