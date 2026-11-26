import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/constant/app_fonts.dart';
import 'package:real_estate/core/constant/app_image_asset.dart';
import 'package:real_estate/core/constant/app_keys.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:real_estate/view/screen/splash_screen.dart';

import '../widget/screen_harness.dart';

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  setUpAll(initScreenTestEnvironment);
  setUp(setUpScreenDependencies);

  testWidgets('English: wordmark and tagline in Outfit, uppercase', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const SplashScreen());
    final TextStyle title = _styleOf(tester, 'REAL SCOUT');
    expect(title.fontFamily, AppFonts.outfit);
    expect(title.letterSpacing, 2);
    expect(title.color, AppPalette.original.primary);

    final TextStyle tagline = _styleOf(
      tester,
      'CONNECTING YOU TO YOUR IDEAL HOME.',
    );
    expect(tagline.fontFamily, AppFonts.outfit);
    expect(tagline.letterSpacing, 1.2);
  });

  testWidgets('Arabic: the wordmark stays Latin, the tagline uses Rubik', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const SplashScreen(), locale: 'ar');
    expect(_styleOf(tester, 'REAL SCOUT').fontFamily, AppFonts.outfit);
    final TextStyle tagline = _styleOf(tester, 'نوصلك إلى منزلك المثالي.');
    expect(tagline.fontFamily, AppFonts.rubik);
    expect(tagline.letterSpacing, 0);
  });

  testWidgets('switching to Arabic retranslates the screen without restart', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, page: () => const SplashScreen());
    expect(find.text('CONNECTING YOU TO YOUR IDEAL HOME.'), findsOneWidget);

    final BuildContext context = tester.element(find.byType(SplashScreen));
    await Get.find<SettingsController>().changeLanguage(context, 'ar');
    await settleFrames(tester, frames: 12);

    expect(find.text('نوصلك إلى منزلك المثالي.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(SplashScreen))),
      TextDirection.rtl,
    );
  });

  for (final PaletteId id in PaletteId.values) {
    testWidgets('uses the ${id.name} logo and title color', (
      WidgetTester tester,
    ) async {
      await setUpScreenDependencies(
        prefs: <String, Object>{SettingsController.paletteKey: id.name},
      );
      await pumpScreen(tester, page: () => const SplashScreen());
      final SvgPicture logo = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byKey(AppKeys.splashLogo),
          matching: find.byType(SvgPicture),
        ),
      );
      final SvgAssetLoader loader = logo.bytesLoader as SvgAssetLoader;
      expect(loader.assetName, AppImageAsset.logo(id));
      expect(logo.colorFilter, isNull, reason: 'gradients must not be tinted');
      expect(
        _styleOf(tester, 'REAL SCOUT').color,
        AppPalette.of(id).primaryText,
      );
      expect(Get.find<SettingsController>().palette.value, id);
    });
  }
}
