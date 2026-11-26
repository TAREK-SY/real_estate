import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constant/app_fonts.dart';
import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/shared/app_asset_image.dart';
import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../tap_area.dart';

/// A labelled row with a minus / value / plus stepper at the end.
///
/// The round buttons are 24; their 48 targets reach 12 past each button.
/// The cluster is shifted by that much toward the end, so the plus button
/// keeps the design's edge and only its invisible target overhangs.
class CounterStepper extends StatelessWidget {
  const CounterStepper({
    required Key super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
    this.step = 1,
  });

  static const double buttonSize = 24;
  static const double gap = 16;
  static const double overhang = (TapArea.minSize - buttonSize) / 2;

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Key self = key!;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: palette.black2,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset((rtl ? -overhang : overhang).w, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _button(
                key: AppKeys.stepperMinus(self),
                icon: AppIcon.minus,
                semantics: AppStrings.tArgs(AppStrings.filterDecrease, <String>[
                  label,
                ]),
                onTap: value > min ? () => onChanged(value - step) : null,
                palette: palette,
              ),
              SizedBox(width: (gap - overhang).w),
              Semantics(
                label: label,
                value: '$value',
                excludeSemantics: true,
                child: LtrText(
                  '$value',
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 16 / 12,
                    color: palette.black1,
                    latinFamily: AppFonts.inter,
                  ),
                ),
              ),
              SizedBox(width: (gap - overhang).w),
              _button(
                key: AppKeys.stepperPlus(self),
                icon: AppIcon.plus,
                semantics: AppStrings.tArgs(AppStrings.filterIncrease, <String>[
                  label,
                ]),
                onTap: value < max ? () => onChanged(value + step) : null,
                palette: palette,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button({
    required Key key,
    required String icon,
    required String semantics,
    required VoidCallback? onTap,
    required AppPalette palette,
  }) {
    return TapArea(
      key: key,
      label: semantics,
      onTap: onTap,
      child: Container(
        width: buttonSize.r,
        height: buttonSize.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.primaryFaint,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: AppAssetImage(
          icon,
          width: 19.r,
          height: 20.r,
          color: palette.primary,
        ),
      ),
    );
  }
}
