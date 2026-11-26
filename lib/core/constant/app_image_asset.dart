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

  static const String authCollage = '$_images/auth_collage.png';
  static const String avatarPlaceholder = '$_images/avatar_placeholder.png';
}

/// Bundled SVG icons (Iconly, exported from the design). Monochrome icons are
/// tinted from the palette at the call site.
abstract final class AppIcon {
  static const String _icons = 'assets/icons';

  static const String notification = '$_icons/ic_notification.svg';
  static const String search = '$_icons/ic_search.svg';
  static const String searchBold = '$_icons/ic_search_bold.svg';
  static const String filter = '$_icons/ic_filter.svg';
  static const String heart = '$_icons/ic_heart.svg';
  static const String star = '$_icons/ic_star.svg';
  static const String homeBold = '$_icons/ic_home_bold.svg';
  static const String homeLight = '$_icons/ic_home_light.svg';
  static const String profileBold = '$_icons/ic_profile_bold.svg';
  static const String profileLight = '$_icons/ic_profile_light.svg';
  static const String google = '$_icons/ic_google.svg';
}
