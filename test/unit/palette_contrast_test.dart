import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:real_estate/core/theme/app_palette.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [top] drawn over [bottom].
Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  test('the original palette uses its primary for text unchanged', () {
    expect(AppPalette.original.primaryText, AppPalette.original.primary);
  });

  test('copyWith derives primaryText from a new primary', () {
    final AppPalette p = AppPalette.orange.copyWith(
      primary: AppPalette.original.primary,
    );
    expect(p.primaryText, AppPalette.original.primary);
    expect(
      AppPalette.orange.copyWith().primaryText,
      AppPalette.orange.primaryText,
    );
  });

  for (final PaletteId id in PaletteId.values) {
    final AppPalette p = AppPalette.of(id);
    test('${id.name}: body text colors meet 4.5:1 on their backgrounds', () {
      expect(_contrast(p.black1, p.white), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.black1, p.inputFill), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(p.black1, _over(p.primaryFaint, p.white)),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(p.black2, p.white), greaterThanOrEqualTo(4.5));
    });

    test('${id.name}: chip, stepper and slider-label colors', () {
      // Unselected chips and stepper values: black1 on the faint fill.
      expect(
        _contrast(p.black1, _over(p.primaryFaint, p.white)),
        greaterThanOrEqualTo(4.5),
      );
      // Filter row labels: black2 on white.
      expect(_contrast(p.black2, p.white), greaterThanOrEqualTo(4.5));
    });

    test('${id.name}: primary text and white on it meet 4.5:1', () {
      // Prices, links and slider labels on white; white labels on selected
      // chips and buttons.
      expect(_contrast(p.primaryText, p.white), greaterThanOrEqualTo(4.5));
    });

    test('${id.name}: primaryText keeps the primary hue', () {
      final HSLColor text = HSLColor.fromColor(p.primaryText);
      final HSLColor base = HSLColor.fromColor(p.primary);
      expect((text.hue - base.hue).abs(), lessThan(1));
      expect(text.lightness, lessThanOrEqualTo(base.lightness));
    });
  }
}
