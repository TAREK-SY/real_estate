import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constant/app_image_asset.dart';
import '../../../core/shared/app_asset_image.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// A Profile menu row: 28 icon, label and a chevron. [destructive] rows
/// (Logout) are red without a chevron. With no [onTap] the row is dimmed
/// and has no chevron, so it does not look like it leads anywhere.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconData,
    this.destructive = false,
  }) : assert(icon != null || iconData != null);

  static const double minHeight = 48;

  /// Space the 48 row adds above and below the 28 icon.
  static const double inset = (minHeight - 28) / 2;

  /// A bundled icon, or [iconData] for one from an icon font.
  final String? icon;
  final IconData? iconData;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool enabled = onTap != null;
    final Color color = destructive ? palette.error : palette.black1;
    final String? asset = icon;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(
              children: <Widget>[
                if (asset != null)
                  AppAssetImage(asset, width: 28.r, height: 28.r, color: color)
                else
                  Icon(iconData, size: 28.r, color: color),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: color,
                    ),
                  ),
                ),
                if (enabled && !destructive)
                  ExcludeSemantics(
                    child: AppAssetImage(
                      AppIcon.arrowRight,
                      width: 20.r,
                      height: 20.r,
                      color: palette.black1,
                      matchTextDirection: true,
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
