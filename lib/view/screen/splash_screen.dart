import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_fonts.dart';
import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    // Centered on the whole screen like the design; the content is small
    // enough that the system bars never cover it.
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppAssetImage(
                AppImageAsset.logo(palette.id),
                key: AppKeys.splashLogo,
                width: 133.885.w,
                height: 112.445.w,
              ),
              SizedBox(height: 12.h),
              Text(
                AppStrings.t(AppStrings.appName).toUpperCase(),
                textAlign: TextAlign.center,
                // The wordmark is a Latin brand name in both languages.
                style: appTextStyle(
                  family: AppFonts.outfit,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: palette.primary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppStrings.t(AppStrings.splashTagline).toUpperCase(),
                textAlign: TextAlign.center,
                style: appTextStyle(
                  latinFamily: AppFonts.outfit,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: palette.black2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
