import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_image_asset.dart';
import '../../core/functions/price_formatter.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/shared/ltr_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Design sizes of the rating pill.
enum RatingPillSize {
  featured(star: 14, text: 12, padH: 10, padV: 4, gap: 4),
  grid(star: 10, text: 10, padH: 6, padV: 4, gap: 2),
  list(star: 8, text: 8, padH: 6, padV: 2, gap: 2);

  const RatingPillSize({
    required this.star,
    required this.text,
    required this.padH,
    required this.padV,
    required this.gap,
  });

  final double star;
  final double text;
  final double padH;
  final double padV;
  final double gap;
}

/// Star and rating on a translucent white pill.
class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating, required this.size});

  final double rating;
  final RatingPillSize size;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String value = formatRating(rating);
    return Semantics(
      label: AppStrings.tArgs(AppStrings.homeRating, <String>[value]),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.padH.w,
          vertical: size.padV.h,
        ),
        decoration: BoxDecoration(
          color: palette.pillBackground,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: palette.pillShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppAssetImage(
              AppIcon.star,
              width: size.star.r,
              height: size.star.r,
            ),
            SizedBox(width: size.gap.w),
            LtrText(
              value,
              style: appTextStyle(
                fontSize: size.text,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: palette.ratingText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
