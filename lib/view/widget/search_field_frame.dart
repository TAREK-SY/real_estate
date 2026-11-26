import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_image_asset.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import 'tap_area.dart';

/// The search bar's box: soft fill, faint border, a [child] filling the
/// start and the filter button at the end.
class SearchFieldFrame extends StatelessWidget {
  const SearchFieldFrame({
    super.key,
    required this.child,
    required this.onFilter,
    this.filterKey,
  });

  static const double height = 52;

  /// Where the leading search icon starts.
  static const double iconInset = 13.5;

  /// Between the search icon and the text.
  static const double iconGap = 16;

  final Widget child;
  final VoidCallback onFilter;
  final Key? filterKey;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Material(
      color: palette.inputFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
        side: BorderSide(color: palette.primaryFaint),
      ),
      child: SizedBox(
        height: height.h,
        child: Row(
          children: <Widget>[
            Expanded(child: child),
            // The icon sits 14.5 from the edge; the 48 target is centered on
            // it, so only half a pixel of padding is left outside.
            Padding(
              padding: EdgeInsetsDirectional.only(end: 0.5.w),
              child: TapArea(
                key: filterKey,
                label: AppStrings.t(AppStrings.homeFilters),
                onTap: onFilter,
                child: AppAssetImage(
                  AppIcon.filter,
                  width: 20.r,
                  height: 20.r,
                  color: palette.black3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The leading magnifier of the search bar.
class SearchFieldIcon extends StatelessWidget {
  const SearchFieldIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAssetImage(
      AppIcon.search,
      width: 20.r,
      height: 20.r,
      color: context.palette.black3,
    );
  }
}
