import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../constant/app_fonts.dart';
import '../util/app_dimensions.dart';

/// Builds a text style for the bundled variable fonts.
///
/// Font choice follows the language, so call sites rarely name a family:
/// - Arabic text always uses Rubik (the only bundled font with Arabic
///   glyphs), and letter spacing is dropped because it pulls joined Arabic
///   letters apart.
/// - English text uses [latinFamily] when given (Outfit, Inter), else Rubik.
/// - [family] forces a font in both languages; use it only for Latin-only
///   content such as the brand wordmark.
///
/// The fonts ship as variable files, and Flutter does not map [FontWeight]
/// to the `wght` axis on its own, so the axis is set next to the weight.
/// [fontSize] is a design value and is scaled with [size].
TextStyle appTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  double? height,
  Color? color,
  double letterSpacing = 0,
  String? latinFamily,
  String? family,
}) {
  final bool arabic = isArabicLocale();
  final String resolvedFamily =
      family ?? (arabic ? AppFonts.rubik : (latinFamily ?? AppFonts.rubik));

  return TextStyle(
    fontFamily: resolvedFamily,
    fontSize: size(fontSize),
    fontWeight: fontWeight,
    fontVariations: <FontVariation>[
      FontVariation('wght', fontWeight.value.toDouble()),
    ],
    height: height,
    color: color,
    letterSpacing: (arabic && family == null) ? 0 : letterSpacing,
  );
}

/// Whether the app currently runs in Arabic.
///
/// Read from `Get.locale`, which `SettingsController` updates before the
/// app rebuilds under a new language.
bool isArabicLocale() => Get.locale?.languageCode == 'ar';
