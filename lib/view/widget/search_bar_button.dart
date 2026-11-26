import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import 'tap_area.dart';

/// The search bar as an entry point: tapping it, or its filter icon, opens
/// the search screen, where the typing happens.
class SearchBarButton extends StatelessWidget {
  const SearchBarButton({
    super.key,
    required this.onSearch,
    required this.onFilter,
  });

  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(6.r);
    return Material(
      color: palette.inputFill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.primaryFaint),
      ),
      child: SizedBox(
        height: 52.h,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                button: true,
                label: AppStrings.t(AppStrings.homeSearchHint),
                onTap: onSearch,
                excludeSemantics: true,
                child: InkWell(
                  key: AppKeys.homeSearch,
                  borderRadius: radius,
                  onTap: onSearch,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: 13.5.w),
                    child: Row(
                      children: <Widget>[
                        AppAssetImage(
                          AppIcon.search,
                          width: 20.r,
                          height: 20.r,
                          color: palette.black3,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            AppStrings.t(AppStrings.homeSearchHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appTextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: palette.black3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The icon sits 14.5 from the edge; the 48 target is centered on
            // it, so only half a pixel of padding is left outside.
            Padding(
              padding: EdgeInsetsDirectional.only(end: 0.5.w),
              child: TapArea(
                key: AppKeys.homeFilter,
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
