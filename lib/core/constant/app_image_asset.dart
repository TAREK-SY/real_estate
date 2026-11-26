import '../theme/app_palette.dart';

/// Bundled image and icon paths.
abstract final class AppImageAsset {
  static const String _images = 'assets/images';

  /// Splash house mark. Each palette has its own gradient, so there is one
  /// file per palette instead of a flat tint.
  static String logo(PaletteId palette) => switch (palette) {
    PaletteId.original => '$_images/logo.svg',
    PaletteId.purple => '$_images/logo_purple.svg',
    PaletteId.orange => '$_images/logo_orange.svg',
  };
}
