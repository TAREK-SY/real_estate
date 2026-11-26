import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_keys.dart';
import '../../core/functions/price_formatter.dart';
import '../../core/localization/category_names.dart';
import '../../core/shared/app_network_image.dart';
import '../../core/shared/ltr_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/model/product.dart';
import 'favorite_button.dart';
import 'rating_pill.dart';
import 'tap_area.dart';

/// Full-width result row: photo, title and location, heart and price.
class PropertyListCard extends StatelessWidget {
  const PropertyListCard({super.key, required this.product});

  static const double imageSize = 100;

  final Product product;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double heartInset = (TapArea.minSize - 22) / 2;
    return Semantics(
      container: true,
      child: Container(
        key: AppKeys.listCard(product.id),
        // The heart's 48 target reaches 13 past the icon, taken out of the
        // 18 end padding; the price keeps the design edge with its own inset.
        padding: EdgeInsetsDirectional.fromSTEB(
          14.w,
          14.w,
          (18 - heartInset).w,
          14.w,
        ),
        decoration: BoxDecoration(
          color: palette.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Stack(
              children: <Widget>[
                AppNetworkImage(
                  url: product.thumbnail,
                  width: imageSize.w,
                  height: imageSize.w,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                PositionedDirectional(
                  top: 6.67.w,
                  end: 6.67.w,
                  child: RatingPill(
                    rating: product.rating,
                    size: RatingPillSize.list,
                  ),
                ),
              ],
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LtrText(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: appTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: palette.black1,
                    ),
                  ),
                  SizedBox(height: 10.w),
                  Text(
                    listingSubtitle(product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appTextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.black2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              height: imageSize.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  FavoriteButton(
                    productId: product.id,
                    title: product.title,
                    color: palette.black2,
                    iconSize: 22,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: heartInset.w,
                      bottom: 10.w,
                    ),
                    child: LtrText(
                      formatPrice(product.price),
                      maxLines: 1,
                      style: appTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: palette.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
