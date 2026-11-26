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
  }
}
