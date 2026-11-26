import 'package:material_ui/material_ui.dart';

/// The three color palettes of the design. Only the primary hue differs
/// between them; neutrals and shadows are shared.
enum PaletteId {
  original,
  purple,
  orange;

  /// Parses a stored name, falling back to [original] for anything unknown.
  static PaletteId fromName(String? name) {
    for (final PaletteId id in values) {
      if (id.name == name) return id;
    }
    return original;
  }
}

/// The single source of colors for the app, read with `context.palette`.
///
/// This file is the only place allowed to declare raw color values.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.primary,
    Color? primaryText,
    this.black1 = const Color(0xFF191D31),
    this.black2 = const Color(0xFF666876),
    this.black3 = const Color(0xFF8C8E98),
    this.white = const Color(0xFFFFFFFF),
    this.inputFill = const Color(0xFFFBFBFD),
    this.imagePlaceholder = const Color(0xFFBDBDBD),
    this.ratingText = const Color(0xFF246BFD),
    this.error = const Color(0xFFF75555),
    this.shadowBase = const Color(0xFF04060F),
    this.buttonShadowBase = const Color(0xFF704F38),
  }) : primaryText = primaryText ?? primary;

  static const AppPalette original = AppPalette(
    id: PaletteId.original,
    primary: Color(0xFF0061FF),
  );

  static const AppPalette purple = AppPalette(
    id: PaletteId.purple,
    primary: Color(0xFF8B5DFF),
    primaryText: Color(0xFF8250FF),
  );

  static const AppPalette orange = AppPalette(
    id: PaletteId.orange,
    primary: Color(0xFFFF8000),
    primaryText: Color(0xFFB55B00),
  );

  static AppPalette of(PaletteId id) => switch (id) {
    PaletteId.original => original,
    PaletteId.purple => purple,
    PaletteId.orange => orange,
  };

  final PaletteId id;
  final Color primary;

  /// The primary hue where text sits on it or is drawn in it (prices, links,
  /// selected chips, buttons). The purple and orange primaries are too light
  /// for 4.5:1 against white, so these palettes use a darker shade of the
  /// same hue; elsewhere it equals [primary].
  final Color primaryText;
  final Color black1;
  final Color black2;
  final Color black3;
  final Color white;
  final Color inputFill;
  final Color imagePlaceholder;
  final Color ratingText;
  final Color error;
  final Color shadowBase;
  final Color buttonShadowBase;

  /// Primary at 10%: back-button fills, chip borders, dividers.
  Color get primarySoft => primary.withValues(alpha: 0.10);

  /// Primary at 4%: unselected chips, tags, search border.
  Color get primaryFaint => primary.withValues(alpha: 0.04);

  /// Ring around the empty page dots, so they show on white product photos
  /// too (the design's photos are never white).
  Color get pagerDotBorder => black3.withValues(alpha: 0.5);

  /// Darkening over the last gallery photo, under its "N+" count.
  Color get photoScrim => const Color(0xFF000000).withValues(alpha: 0.40);

  /// Scrim behind bottom sheets.
  Color get overlay => const Color(0xFF000000).withValues(alpha: 0.30);

  /// Card shadow: (0, 4) blur 30 at 5%.
  List<BoxShadow> get cardShadow => <BoxShadow>[
    BoxShadow(
      color: shadowBase.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 30,
    ),
  ];

  /// Rating pill shadow: (0, 20) blur 100 at 12%.
  List<BoxShadow> get pillShadow => <BoxShadow>[
    BoxShadow(
      color: shadowBase.withValues(alpha: 0.12),
      offset: const Offset(0, 20),
      blurRadius: 100,
    ),
  ];

  /// Primary button shadow: (4, 8) blur 12 at 25%.
  List<BoxShadow> get buttonShadow => <BoxShadow>[
    BoxShadow(
      color: buttonShadowBase.withValues(alpha: 0.25),
      offset: const Offset(4, 8),
      blurRadius: 12,
    ),
  ];

  /// Google sign-in button shadow: (0, 4) blur 60 black at 20%.
  List<BoxShadow> get googleButtonShadow => <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.20),
      offset: const Offset(0, 4),
      blurRadius: 60,
    ),
  ];

  /// Rating pill background: white at 90%.
  Color get pillBackground => white.withValues(alpha: 0.90);

  /// Darkening under the featured card text, top to bottom (8 design stops).
  LinearGradient get featuredScrim => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: <double>[0, 0.17187, 0.27083, 0.41667, 0.52604, 0.66146, 0.80208, 1],
    colors: <Color>[
      Color(0x004B4B4B),
      Color(0x1D444444),
      Color(0x2E404040),
      Color(0x473A3A3A),
      Color(0x59363636),
      Color(0x762F2F2F),
      Color(0x8F282828),
      Color(0xB2202020),
    ],
  );

  @override
  AppPalette copyWith({PaletteId? id, Color? primary, Color? primaryText}) =>
      AppPalette(
        id: id ?? this.id,
        primary: primary ?? this.primary,
        primaryText: primaryText ?? (primary == null ? this.primaryText : null),
        black1: black1,
        black2: black2,
        black3: black3,
        white: white,
        inputFill: inputFill,
        imagePlaceholder: imagePlaceholder,
        ratingText: ratingText,
        error: error,
        shadowBase: shadowBase,
        buttonShadowBase: buttonShadowBase,
      );

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      primary: mix(primary, other.primary),
      primaryText: mix(primaryText, other.primaryText),
      black1: mix(black1, other.black1),
      black2: mix(black2, other.black2),
      black3: mix(black3, other.black3),
      white: mix(white, other.white),
      inputFill: mix(inputFill, other.inputFill),
      imagePlaceholder: mix(imagePlaceholder, other.imagePlaceholder),
      ratingText: mix(ratingText, other.ratingText),
      error: mix(error, other.error),
      shadowBase: mix(shadowBase, other.shadowBase),
      buttonShadowBase: mix(buttonShadowBase, other.buttonShadowBase),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The active palette. Falls back to [AppPalette.original] when a widget is
  /// built outside the app theme (some isolated widget tests).
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.original;
}
