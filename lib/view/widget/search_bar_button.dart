import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import 'search_field_frame.dart';

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
    return SearchFieldFrame(
      filterKey: AppKeys.homeFilter,
      onFilter: onFilter,
      child: Semantics(
        button: true,
        label: AppStrings.t(AppStrings.homeSearchHint),
        onTap: onSearch,
        excludeSemantics: true,
        child: InkWell(
          key: AppKeys.homeSearch,
          borderRadius: BorderRadius.circular(6.r),
          onTap: onSearch,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: SearchFieldFrame.iconInset.w,
            ),
            child: Row(
              children: <Widget>[
                const SearchFieldIcon(),
                SizedBox(width: SearchFieldFrame.iconGap.w),
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
    );
  }
}
