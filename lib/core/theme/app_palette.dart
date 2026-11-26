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
  });

  static const AppPalette original = AppPalette(
    id: PaletteId.original,
    primary: Color(0xFF0061FF),
  );

  static const AppPalette purple = AppPalette(
    id: PaletteId.purple,
    primary: Color(0xFF8B5DFF),
  );

  static const AppPalette orange = AppPalette(
    id: PaletteId.orange,
    primary: Color(0xFFFF8000),
  );

  static AppPalette of(PaletteId id) => switch (id) {
    PaletteId.original => original,
    PaletteId.purple => purple,
    PaletteId.orange => orange,
  };

  final PaletteId id;
  final Color primary;
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

  @override
  AppPalette copyWith({PaletteId? id, Color? primary}) => AppPalette(
    id: id ?? this.id,
    primary: primary ?? this.primary,
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
