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

/// White card with a photo, title, location and price (Home recommendations
/// and the grid search results). Takes the width it is given.
class PropertyGridCard extends StatelessWidget {
  const PropertyGridCard({super.key, required this.product, this.onTap});

  static const double imageHeight = 154;

  final Product product;

  /// Opens the listing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    // Its own node, so a screen reader does not read two cards of a row as
    // one item.
    final BorderRadius radius = BorderRadius.circular(12.r);
    return Semantics(
      container: true,
      // Material clips the ink it paints to its own size, so the shadow,
      // which falls outside the card, has to be drawn above it.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: palette.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            key: AppKeys.gridCard(product.id),
            decoration: BoxDecoration(
              color: palette.white,
              borderRadius: radius,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                // The heart's 48 touch target adds 14 below the price row, taken out
                // of the 20 bottom padding.
                padding: EdgeInsetsDirectional.fromSTEB(14.w, 16.w, 14.w, 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        AppNetworkImage(
                          url: product.thumbnail,
                          width: double.infinity,
                          height: imageHeight.w,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        PositionedDirectional(
                          top: 12.w,
                          end: 12.w,
                          child: RatingPill(
                            rating: product.rating,
                            size: RatingPillSize.grid,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.w),
                    LtrText(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: palette.black1,
                      ),
                    ),
                    SizedBox(height: 10.w),
                    Text(
                      listingSubtitle(product),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(fontSize: 12, color: palette.black3),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LtrText(
                            formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: palette.primaryText,
                            ),
                          ),
                        ),
                        FavoriteButton(
                          productId: product.id,
                          title: product.title,
                          color: palette.black2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
