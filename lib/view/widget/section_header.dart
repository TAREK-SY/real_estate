import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Section title with an optional "See All" link.
///
/// The row is 48 tall so the link meets the touch-target size; callers take
/// the extra [inset] above and below out of the design gaps.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllKey,
    this.leading,
  });

  static const double height = 48;

  /// Space the row adds above and below the 24 tall design text.
  static const double inset = 12;

  final String title;
  final VoidCallback? onSeeAll;
  final Key? seeAllKey;

  /// Shown before the title, 12 apart (the reviews star).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return SizedBox(
      height: height,
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[leading!, SizedBox(width: 12.w)],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: palette.black1,
                ),
              ),
            ),
          ),
          if (onSeeAll != null) ...<Widget>[
            SizedBox(width: 12.w),
            InkWell(
              key: seeAllKey,
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8.r),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: height,
                  minWidth: height,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    AppStrings.t(AppStrings.homeSeeAll),
                    style: appTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: palette.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
