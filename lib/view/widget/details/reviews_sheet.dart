import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/model/review.dart';
import '../circle_icon_button.dart';
import '../tap_area.dart';
import '../titled_head_row.dart';
import 'review_tile.dart';

/// Opens every review of a listing in a bottom sheet ("See All").
Future<void> showReviewsSheet(BuildContext context, List<Review> reviews) {
  final AppPalette palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.white,
    barrierColor: palette.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => ReviewsSheet(reviews: reviews),
  );
}

class ReviewsSheet extends StatelessWidget {
  const ReviewsSheet({super.key, required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: AppKeys.reviewsSheet,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: TitledHeadRow(
                title: AppStrings.t(AppStrings.detailsReviewsTitle),
                leading: CircleIconButton(
                  key: AppKeys.reviewsClose,
                  icon: AppIcon.arrowLeft,
                  label: AppStrings.t(AppStrings.profileCloseSheet),
                  soft: true,
                  matchTextDirection: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                trailing: const SizedBox.square(dimension: TapArea.minSize),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => SizedBox(height: 24.h),
                itemBuilder: (_, int index) =>
                    ReviewTile(review: reviews[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
