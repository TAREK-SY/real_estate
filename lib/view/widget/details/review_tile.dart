import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/functions/relative_time.dart';
import '../../../core/shared/initials_avatar.dart';
import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/model/review.dart';

/// One review: initials, name, comment and how long ago it was written.
/// The API has no like counts, so the design's heart row keeps only the
/// date.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.now});

  final Review review;

  /// Reference time for the date; the current time when null.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final DateTime? date = review.date;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              InitialsAvatar(name: review.reviewerName, size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: LtrText(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: palette.black1,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...<Widget>[
            SizedBox(height: 12.h),
            // Comments arrive in English.
            LtrText(
              review.comment,
              style: appTextStyle(
                fontSize: 16,
                height: 1.7,
                color: palette.black2,
              ),
            ),
          ],
          if (date != null) ...<Widget>[
            SizedBox(height: 12.h),
            Text(
              relativeTime(date, now ?? DateTime.now()),
              textAlign: TextAlign.end,
              style: appTextStyle(fontSize: 14, color: palette.black3),
            ),
          ],
        ],
      ),
    );
  }
}
