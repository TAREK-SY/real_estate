import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../controller/auth/auth_controller.dart';
import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../widget/google_sign_in_button.dart';

class AuthScreen extends GetView<AuthController> {
  const AuthScreen({super.key});

  /// The text block starts 33 above the collage's bottom edge, over its
  /// fade-out (design: collage 83..635, text from 602).
  static const double _overlap = 33;

  void _onGoogle(BuildContext context) {
    // A second tap can land before the disabled button is rebuilt.
    if (controller.isSigningIn.value) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t(AppStrings.authGuestNotice))),
    );
    controller.continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextStyle headline = appTextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: palette.black1,
    );

    return Scaffold(
      backgroundColor: palette.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 39.h, bottom: 24.h),
          child: Column(
            children: <Widget>[
              // A single exported image: eleven photos in three staggered
              // columns, already faded into the background at the bottom.
              AppAssetImage(
                AppImageAsset.authCollage,
                width: 399.w,
                height: 552.w,
                fit: BoxFit.cover,
              ),
              Transform.translate(
                offset: Offset(0, -_overlap.w),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: <Widget>[
                      Text(
                        AppStrings.t(AppStrings.authWelcome).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: appTextStyle(
                          fontSize: 16,
                          height: 1.8,
                          letterSpacing: 1.6,
                          color: palette.black2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Semantics(
                        header: true,
                        child: Text.rich(
                          TextSpan(
                            style: headline,
                            children: <InlineSpan>[
                              TextSpan(
                                text:
                                    '${AppStrings.t(AppStrings.authTitleLine1)}\n',
                              ),
                              TextSpan(
                                text: AppStrings.t(AppStrings.authTitleTo),
                              ),
                              TextSpan(
                                text: AppStrings.t(
                                  AppStrings.authTitleHighlight,
                                ),
                                style: headline.copyWith(
                                  color: palette.primaryText,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        AppStrings.t(AppStrings.authSubtitle),
                        textAlign: TextAlign.center,
                        style: appTextStyle(
                          fontSize: 18,
                          height: 1.8,
                          color: palette.black2,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Obx(
                        () => GoogleSignInButton(
                          key: AppKeys.googleSignIn,
                          label: AppStrings.t(AppStrings.authGoogle),
                          onPressed: controller.isSigningIn.value
                              ? null
                              : () => _onGoogle(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
