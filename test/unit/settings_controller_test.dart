import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/controller/settings/settings_controller.dart';
import 'package:real_estate/core/services/services.dart';
import 'package:real_estate/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsController> _controller(Map<String, Object> prefs) async {
  Get.reset();
  SharedPreferences.setMockInitialValues(prefs);
  await Get.putAsync<MyServices>(() => MyServices().init(), permanent: true);
  return Get.put<SettingsController>(SettingsController(), permanent: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  group('palette', () {
    test('defaults to the original palette', () async {
      final SettingsController controller = await _controller(
        <String, Object>{},
      );
      expect(controller.palette.value, PaletteId.original);
      expect(controller.currentPalette, AppPalette.original);
    });

    test('restores the saved palette', () async {
      final SettingsController controller = await _controller(<String, Object>{
        SettingsController.paletteKey: 'orange',
      });
      expect(controller.palette.value, PaletteId.orange);
    });

    test('a corrupted saved value falls back to the original', () async {
      final SettingsController controller = await _controller(<String, Object>{
        SettingsController.paletteKey: '???',
      });
      expect(controller.palette.value, PaletteId.original);
    });

    test('changing the palette updates state and storage', () async {
      final SettingsController controller = await _controller(
        <String, Object>{},
      );
      await controller.changePalette(PaletteId.purple);
      expect(controller.palette.value, PaletteId.purple);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsController.paletteKey), 'purple');
    });
  });

  group('startLocale', () {
    test('uses the saved language first', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsController.languageKey: 'ar',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        SettingsController.startLocale(prefs, const Locale('en', 'US')),
        const Locale('ar'),
      );
    });

    test('falls back to a supported device language', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        SettingsController.startLocale(prefs, const Locale('ar', 'SA')),
        const Locale('ar'),
      );
    });

    test('falls back to English for other device languages', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SettingsController.languageKey: 'fr',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        SettingsController.startLocale(prefs, const Locale('de')),
        const Locale('en'),
      );
    });
  });
}
