import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// Two-thumb slider of the filter sheet with its values printed under the
/// thumbs.
///
/// The track spans the full width and the thumbs are centered on their
/// values, so a thumb at an end hangs half outside, as in the design. The
/// slider box is 48 tall for the touch target, 12 above and below the
/// 24 thumbs; the labels sit 8 below the thumbs, kept inside the track.
class AppRangeSlider extends StatelessWidget {
  const AppRangeSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
    this.divisions,
    this.labelFamily,
  });

  static const double sliderHeight = 48;
  static const double thumbSize = 24;
  static const double labelGap = 8;
  static const double labelHeight = 16;

  /// Room above the thumbs inside the slider box.
  static const double inset = (sliderHeight - thumbSize) / 2;
  static const double height = sliderHeight - inset + labelGap + labelHeight;

  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) format;
  final ValueChanged<RangeValues> onChanged;

  /// Latin font of the labels (Inter for plain numbers in the design).
  final String? labelFamily;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final TextStyle labelStyle = appTextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: labelHeight / 12,
      color: palette.primaryText,
      latinFamily: labelFamily,
    );

    return SizedBox(
      height: height.h,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          double fraction(double v) => max > min ? (v - min) / (max - min) : 0;

          Widget label(double value) {
            final double f = fraction(value);
            return Positioned(
              top: (sliderHeight - inset + labelGap).h,
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomSingleChildLayout(
                delegate: _LabelLayout(rtl ? 1 - f : f),
                child: ExcludeSemantics(
                  child: LtrText(format(value), style: labelStyle),
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                bottom: null,
                child: SizedBox(
                  height: sliderHeight.h,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: palette.primary,
                      inactiveTrackColor: palette.primarySoft,
                      overlayShape: SliderComponentShape.noOverlay,
                      rangeThumbShape: _RingThumbShape(
                        radius: (thumbSize / 2).r,
                        fill: palette.white,
                        ring: palette.primary,
                      ),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: RangeSlider(
                      values: values,
                      min: min,
                      max: max,
                      divisions: divisions,
                      padding: EdgeInsets.symmetric(vertical: inset.h),
                      semanticFormatterCallback: format,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
              label(values.start),
              label(values.end),
            ],
          );
        },
      ),
    );
  }
}

/// Centers a label under its thumb, but keeps it inside the slider's width:
/// a thumb at an end hangs half outside, and a wide value would be clipped.
class _LabelLayout extends SingleChildLayoutDelegate {
  const _LabelLayout(this.fraction);

  /// Thumb position from the left edge, 0..1.
  final double fraction;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double room = size.width - childSize.width;
    final double x = size.width * fraction - childSize.width / 2;
    return Offset(room > 0 ? x.clamp(0, room) : 0, 0);
  }

  @override
  bool shouldRelayout(_LabelLayout oldDelegate) =>
      oldDelegate.fraction != fraction;
}

/// White thumb with a primary ring.
class _RingThumbShape extends RangeSliderThumbShape {
  const _RingThumbShape({
    required this.radius,
    required this.fill,
    required this.ring,
  });

  final double radius;
  final Color fill;
  final Color ring;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    const double stroke = 2;
    final Canvas canvas = context.canvas;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius - stroke / 2,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }
}
