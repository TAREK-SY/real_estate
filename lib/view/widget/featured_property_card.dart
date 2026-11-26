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

/// 250 x 340 photo card with the title, location and price over a dark
/// gradient (Home "Featured").
class FeaturedPropertyCard extends StatelessWidget {
  const FeaturedPropertyCard({super.key, required this.product, this.onTap});

  static const double width = 250;
  static const double height = 340;

  /// The gradient covers the card from 53.53% of its height down.
  static const double scrimStart = 0.5353;

  final Product product;

  /// Opens the listing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(20.r);
    final double cardHeight = height.w;
    final Color onImage = palette.white;

    return SizedBox(
      key: AppKeys.featuredCard(product.id),
      width: width.w,
      height: cardHeight,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: AppNetworkImage(
                  url: product.thumbnail,
                  width: width.w,
                  height: cardHeight,
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: cardHeight * (1 - scrimStart),
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: palette.featuredScrim),
                ),
              ),
              PositionedDirectional(
                top: 24.w,
                end: 24.w,
                child: RatingPill(
                  rating: product.rating,
                  size: RatingPillSize.featured,
                ),
              ),
              // The heart's 48 touch target adds 12 below the price row, taken
              // out of the 20 bottom margin.
              PositionedDirectional(
                start: 16.w,
                end: 16.w,
                bottom: 8.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LtrText(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: onImage,
                      ),
                    ),
                    SizedBox(height: 10.w),
                    Text(
                      listingSubtitle(product),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appTextStyle(
                        fontSize: 16,
                        height: 1.4,
                        letterSpacing: 0.2,
                        color: onImage,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LtrText(
                            formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appTextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: onImage,
                            ),
                          ),
                        ),
                        FavoriteButton(
                          productId: product.id,
                          title: product.title,
                          color: onImage,
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
