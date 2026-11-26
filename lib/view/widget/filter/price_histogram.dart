import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_palette.dart';

/// Bars of item counts across the price scale, drawn above the price
/// slider. Follows the text direction like the slider under it.
class PriceHistogram extends StatelessWidget {
  const PriceHistogram({super.key, required this.counts});

  /// Bar width over the bar step (15.471 / 19.47 in the design).
  static const double barRatio = 15.471 / 19.47;

  /// Lowest visible bar, so a bucket with few items still shows.
  static const double minBar = 3;

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HistogramPainter(
          counts: counts,
          color: context.palette.primarySoft,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.counts,
    required this.color,
    required this.rtl,
  });

  final List<int> counts;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final int highest = counts.reduce(math.max);
    if (highest == 0) return;
    final double step = size.width / counts.length;
    final double bar = step * PriceHistogram.barRatio;
    final Paint paint = Paint()..color = color;
    for (int i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      final double h = math.max(
        PriceHistogram.minBar,
        size.height * counts[i] / highest,
      );
      final int slot = rtl ? counts.length - 1 - i : i;
      canvas.drawRect(
        Rect.fromLTWH(slot * step, size.height - h, bar, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) =>
      old.color != color || old.rtl != rtl || !listEquals(old.counts, counts);
}
