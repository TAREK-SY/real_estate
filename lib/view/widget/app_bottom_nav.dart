import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../controller/main/main_controller.dart';
import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Home / Explore / Profile bar with a soft top border.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final MainTab current;
  final ValueChanged<MainTab> onTap;

  static String _activeIcon(MainTab tab) => switch (tab) {
    MainTab.home => AppIcon.homeBold,
    MainTab.explore => AppIcon.searchBold,
    MainTab.profile => AppIcon.profileBold,
  };

  static String _inactiveIcon(MainTab tab) => switch (tab) {
    MainTab.home => AppIcon.homeLight,
    MainTab.explore => AppIcon.search,
    MainTab.profile => AppIcon.profileLight,
  };

  static String _label(MainTab tab) => switch (tab) {
    MainTab.home => AppStrings.navHome,
    MainTab.explore => AppStrings.navExplore,
    MainTab.profile => AppStrings.navProfile,
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    // A Material (not a colored box) so the tab ripples are painted on top
    // of the bar's background.
    return Material(
      key: AppKeys.bottomNav,
      color: palette.white,
      shape: Border(top: BorderSide(color: palette.primarySoft)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final MainTab tab in MainTab.values)
                _NavItem(
                  key: AppKeys.navTab(tab.index),
                  icon: tab == current ? _activeIcon(tab) : _inactiveIcon(tab),
                  label: AppStrings.t(_label(tab)),
                  selected: tab == current,
                  onTap: () => onTap(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = selected ? palette.primary : palette.black2;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppAssetImage(icon, width: 24.r, height: 24.r, color: color),
              SizedBox(height: 6.r),
              Text(
                label,
                maxLines: 1,
                style: appTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
