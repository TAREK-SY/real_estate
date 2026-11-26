import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constant/app_keys.dart';
import '../../../core/functions/price_formatter.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/shared/ltr_text.dart';
import '../../../core/shared/primary_button.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// The details screen's fixed bottom bar: price on one side, "Booking Now"
/// filling the rest.
class PriceBookingBar extends StatelessWidget {
  const PriceBookingBar({
    super.key,
    required this.price,
    required this.isBooking,
    required this.onBook,
  });

  final double price;
  final bool isBooking;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.white,
        border: Border.all(color: palette.primarySoft),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: 36.h),
        child: Row(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.t(AppStrings.detailsPrice).toUpperCase(),
                  style: appTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: palette.black2,
                  ),
                ),
                SizedBox(height: 6.h),
                LtrText(
                  formatPrice(price),
                  maxLines: 1,
                  style: appTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: palette.primaryText,
                  ),
                ),
              ],
            ),
            SizedBox(width: 60.w),
            Expanded(
              child: PrimaryButton(
                key: AppKeys.detailsBook,
                label: AppStrings.t(AppStrings.detailsBook),
                verticalPadding: 14,
                isLoading: isBooking,
                onPressed: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
