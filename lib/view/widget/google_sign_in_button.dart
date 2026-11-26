import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_image_asset.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-width white pill with the Google logo and a label.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(30.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: palette.googleButtonShadow,
      ),
      child: Material(
        color: palette.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.primaryFaint),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AppAssetImage(AppIcon.google, width: 22.r, height: 22.r),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: palette.black1,
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
