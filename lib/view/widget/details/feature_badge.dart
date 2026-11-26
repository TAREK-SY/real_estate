import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/shared/app_asset_image.dart';
import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// A 16 icon in a faint circle followed by a short label ("5 in stock").
class FeatureBadge extends StatelessWidget {
  const FeatureBadge({
    super.key,
    required this.icon,
    required this.label,
    this.leftToRight = false,
  });

  final String icon;
  final String label;

  /// For labels made only of numbers and symbols ("23 × 14 × 28"), which an
  /// Arabic line would otherwise reorder.
  final bool leftToRight;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextStyle style = appTextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: palette.black1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: palette.primaryFaint,
            shape: BoxShape.circle,
          ),
          child: AppAssetImage(
            icon,
            width: 16.r,
            height: 16.r,
            color: palette.primary,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: leftToRight
              ? LtrText(label, style: style)
              : Text(label, style: style),
        ),
      ],
    );
  }
}
