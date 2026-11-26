import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/services.dart';
import '../../core/theme/app_palette.dart';

/// Language and palette choices, persisted and restored on launch.
///
/// Both changes apply immediately: the palette is observed by [MyApp]'s
/// theme, and the language goes through easy_localization, which rebuilds
/// the app under the new locale and text direction.
class SettingsController extends GetxController {
  static const String languageKey = 'settings.language';
  static const String paletteKey = 'settings.palette';

  static const List<String> supportedLanguageCodes = <String>['en', 'ar'];
  static const String fallbackLanguageCode = 'en';

  final Rx<PaletteId> palette = PaletteId.original.obs;

  SharedPreferences get _prefs => Get.find<MyServices>().sharedPreferences;

  @override
  void onInit() {
    super.onInit();
    palette.value = PaletteId.fromName(_prefs.getString(paletteKey));
  }

  AppPalette get currentPalette => AppPalette.of(palette.value);

  Future<void> changePalette(PaletteId id) async {
    if (palette.value == id) return;
    palette.value = id;
    await _prefs.setString(paletteKey, id.name);
  }

  Future<void> changeLanguage(BuildContext context, String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    // Looked up before any await: the caller (a sheet, say) may be gone by
    // then, and the switch must not stop halfway.
    // The provider type is private to easy_localization, hence no annotation.
    final localization = ez.EasyLocalization.of(context);
    if (localization == null) return;
    final Locale locale = Locale(code);
    // Set before the rebuild so anything reading Get.locale sees the new one.
    Get.locale = locale;
    await localization.setLocale(locale);
    await _prefs.setString(languageKey, code);
  }

  /// The locale to start with: the saved one, else the device language when
  /// supported, else English.
  static Locale startLocale(SharedPreferences prefs, Locale deviceLocale) {
    final String? saved = prefs.getString(languageKey);
    if (saved != null && supportedLanguageCodes.contains(saved)) {
      return Locale(saved);
    }
    final String device = deviceLocale.languageCode;
    return Locale(
      supportedLanguageCodes.contains(device) ? device : fallbackLanguageCode,
    );
  }
}
