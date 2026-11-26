import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import 'tap_area.dart';

/// Round 44 icon button of the head rows. [soft] uses the faint primary
/// background of the back button; otherwise white.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.soft = false,
    this.iconSize = 22,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool soft;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return TapArea(
      label: label,
      onTap: onPressed,
      child: Container(
        width: 44.r,
        height: 44.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: soft ? palette.primarySoft : palette.white,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: AppAssetImage(
          icon,
          width: iconSize.r,
          height: iconSize.r,
          color: palette.black1,
        ),
      ),
    );
  }
}
