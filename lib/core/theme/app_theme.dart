import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../constant/app_fonts.dart';
import 'app_palette.dart';

/// Builds the app theme for a palette.
///
/// Rubik covers Latin and Arabic, so the theme does not depend on the locale.
ThemeData buildAppTheme(AppPalette palette) {
  final ColorScheme scheme = ColorScheme.light(
    primary: palette.primary,
    onPrimary: palette.white,
    secondary: palette.primary,
    surface: palette.white,
    onSurface: palette.black1,
    error: palette.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.rubik,
    scaffoldBackgroundColor: palette.white,
    splashFactory: InkSparkle.splashFactory,
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.primary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.primary,
      selectionColor: palette.primary.withValues(alpha: 0.4),
      selectionHandleColor: palette.primary,
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}

/// System bars as in the design: a see-through status bar with dark icons
/// over the white screens, and a white navigation bar.
SystemUiOverlayStyle appSystemUiStyle(AppPalette palette) =>
    SystemUiOverlayStyle(
      statusBarColor: palette.white.withValues(alpha: 0),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: palette.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: palette.white,
    );
