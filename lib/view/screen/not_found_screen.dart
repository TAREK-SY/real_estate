import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/primary_button.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppStrings.t(AppStrings.notFoundTitle),
                  textAlign: TextAlign.center,
                  style: appTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: palette.black1,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppStrings.t(AppStrings.notFoundSubtitle),
                  textAlign: TextAlign.center,
                  style: appTextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: palette.black2,
                  ),
                ),
                SizedBox(height: 24.h),
                PrimaryButton(
                  key: AppKeys.notFoundAction,
                  label: AppStrings.t(AppStrings.notFoundAction),
                  onPressed: () => Get.offAllNamed<void>(AppRoute.splash),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
