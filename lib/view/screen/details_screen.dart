import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../controller/details/details_controller.dart';
import '../../core/class/handling_data_view.dart';
import '../../core/class/status_request.dart';
import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/functions/price_formatter.dart';
import '../../core/functions/status_message.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/category_names.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/shared/app_divider.dart';
import '../../core/shared/ltr_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/model/category.dart';
import '../../data/model/product.dart';
import '../widget/details/facility_grid.dart';
import '../widget/details/feature_badge.dart';
import '../widget/details/gallery_row.dart';
import '../widget/details/image_pager.dart';
import '../widget/details/price_booking_bar.dart';
import '../widget/details/review_tile.dart';
import '../widget/details/reviews_sheet.dart';
import '../widget/favorite_button.dart';
import '../widget/section_header.dart';
import '../widget/tap_area.dart';

/// One listing: photo pager, facts, overview, tags, gallery, reviews and a
/// fixed price bar with the (simulated) booking.
///
/// The design's agent and map sections have no source in the API and are
/// left out.
class DetailsScreen extends GetView<DetailsController> {
  const DetailsScreen({super.key});

  static const double heroHeight = 460;

  /// Space a 28 icon's 48 touch target adds on each side.
  static const double iconInset = (TapArea.minSize - 28) / 2;

  Future<void> _book(BuildContext context) async {
    // Looked up before the await; the screen may be gone when it returns.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final StatusRequest result = await controller.book();
    if (result == StatusRequest.none) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              result == StatusRequest.success
                  ? AppStrings.detailsBookingSent
                  : statusMessageKey(result),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Obx(() {
      final Product? product = controller.product.value;
      final StatusRequest status = controller.status.value;
      if (product == null) {
        return Scaffold(
          backgroundColor: palette.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    (24 - iconInset).w,
                    (16 - iconInset).h,
                    0,
                    0,
                  ),
                  child: const _BackButton(),
                ),
                Expanded(
                  child: HandlingDataView(
                    status: status,
                    onRetry: controller.load,
                    child: const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: palette.white,
        body: _StatusBarBackdrop(
          revealAfter: DetailsScreen.heroHeight.w,
          builder: (ScrollController scroll) => CustomScrollView(
            key: AppKeys.detailsScroll,
            controller: scroll,
            slivers: <Widget>[
              SliverToBoxAdapter(child: _Header(product: product)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
                sliver: SliverList.list(
                  children: _body(context, product, status),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PriceBookingBar(
          price: product.price,
          isBooking: controller.isBooking.value,
          onBook: () => _book(context),
        ),
      );
    });
  }

  List<Widget> _body(
    BuildContext context,
    Product product,
    StatusRequest status,
  ) {
    final AppPalette palette = context.palette;
    final double sectionGap = (30 - SectionHeader.inset).h;
    final List<String> gallery = product.images.skip(1).toList();
    return <Widget>[
      _Summary(product: product),
      SizedBox(height: 30.h),
      const AppDivider(),
      if (product.description.isNotEmpty) ...<Widget>[
        SizedBox(height: sectionGap),
        SectionHeader(title: AppStrings.t(AppStrings.detailsOverview)),
        // Descriptions arrive in English.
        LtrText(
          product.description,
          style: appTextStyle(fontSize: 16, height: 1.7, color: palette.black2),
        ),
      ],
      if (product.tags.isNotEmpty) ...<Widget>[
        SizedBox(height: sectionGap),
        SectionHeader(title: AppStrings.t(AppStrings.detailsFacilities)),
        SizedBox(height: (20 - SectionHeader.inset).h),
        FacilityGrid(labels: product.tags),
      ],
      if (gallery.isNotEmpty) ...<Widget>[
        SizedBox(height: sectionGap),
        SectionHeader(title: AppStrings.t(AppStrings.detailsGallery)),
        SizedBox(height: (20 - SectionHeader.inset).h),
        GalleryRow(photos: gallery),
      ],
      if (product.reviews.isNotEmpty) ...<Widget>[
        SizedBox(height: sectionGap),
        _ReviewsHeader(product: product),
        SizedBox(height: (24 - SectionHeader.inset).h),
        ReviewTile(review: product.reviews.first),
      ],
      if (status == StatusRequest.loading) ...<Widget>[
        SizedBox(height: 30.h),
        SizedBox(height: 64.h, child: const LoadingView()),
      ] else if (status.isFailure) ...<Widget>[
        SizedBox(height: 30.h),
        StateMessageView(
          messageKey: AppStrings.detailsLoadFailed,
          onRetry: canRetry(status) ? controller.load : null,
        ),
      ],
    ];
  }
}

/// The photo runs under the status bar, as in the design. Once it has
/// scrolled away, a white band fades in behind the status bar so the clock
/// never sits on top of text.
class _StatusBarBackdrop extends StatefulWidget {
  const _StatusBarBackdrop({required this.revealAfter, required this.builder});

  /// Scroll offset (the photo height) at which the band is fully shown.
  final double revealAfter;
  final Widget Function(ScrollController scroll) builder;

  @override
  State<_StatusBarBackdrop> createState() => _StatusBarBackdropState();
}

class _StatusBarBackdropState extends State<_StatusBarBackdrop> {
  final ScrollController _scroll = ScrollController();
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_update);
  }

  void _update() {
    final double top = MediaQuery.paddingOf(context).top;
    final bool shown = _scroll.offset > widget.revealAfter - top;
    if (shown != _shown) setState(() => _shown = shown);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.builder(_scroll),
        PositionedDirectional(
          start: 0,
          end: 0,
          top: 0,
          height: MediaQuery.paddingOf(context).top,
          child: IgnorePointer(
            child: AnimatedOpacity(
              key: AppKeys.detailsStatusBackdrop,
              opacity: _shown ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: ColoredBox(color: context.palette.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return TapArea(
      key: AppKeys.detailsBack,
      label: AppStrings.t(AppStrings.detailsBack),
      onTap: Get.back,
      child: AppAssetImage(
        AppIcon.arrowLeftLight,
        width: 28.r,
        height: 28.r,
        color: context.palette.black1,
        matchTextDirection: true,
      ),
    );
  }
}

/// Photo pager with the back, favorite and share buttons over it.
class _Header extends GetView<DetailsController> {
  const _Header({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double inset = DetailsScreen.iconInset;
    // The design's buttons sit 28 below the status bar.
    final double top = MediaQuery.paddingOf(context).top + (28 - inset).h;
    return Stack(
      children: <Widget>[
        Obx(
          () => ImagePager(
            photos: DetailsController.photosOf(product),
            current: controller.photoIndex.value,
            onChanged: controller.showPhoto,
            height: DetailsScreen.heroHeight.w,
          ),
        ),
        PositionedDirectional(
          top: top,
          start: (24 - inset).w,
          end: (24 - inset).w,
          child: Row(
            children: <Widget>[
              const _BackButton(),
              const Spacer(),
              FavoriteButton(
                productId: product.id,
                title: product.title,
                color: palette.black1,
                iconSize: 28,
              ),
              // Sharing is not part of this app: shown, but disabled.
              TapArea(
                key: AppKeys.detailsShare,
                label: AppStrings.t(AppStrings.detailsShare),
                onTap: null,
                child: AppAssetImage(
                  AppIcon.send,
                  width: 28.r,
                  height: 28.r,
                  color: palette.black1,
                  matchTextDirection: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Title, category tag with the rating, and the three facts.
class _Summary extends StatelessWidget {
  const _Summary({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double? weight = product.weight;
    final ProductDimensions? dimensions = product.dimensions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: LtrText(
            product.title,
            style: appTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: palette.black1,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 8.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: palette.primaryFaint,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                categoryDisplayName(
                  Category(slug: product.category, name: product.category),
                ).toUpperCase(),
                style: appTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppAssetImage(AppIcon.star, width: 20.r, height: 20.r),
                SizedBox(width: 6.w),
                Text(
                  _ratingSummary(product),
                  style: appTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: palette.black2,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 24.w,
          runSpacing: 12.h,
          children: <Widget>[
            if (product.stock != null)
              FeatureBadge(
                icon: AppIcon.bed,
                label: AppStrings.tArgs(AppStrings.detailsStock, <String>[
                  '${product.stock}',
                ]),
              ),
            if (weight != null && weight.isFinite)
              FeatureBadge(
                icon: AppIcon.bath,
                label: AppStrings.tArgs(AppStrings.detailsWeight, <String>[
                  formatMeasure(weight),
                ]),
              ),
            if (dimensions != null)
              FeatureBadge(
                icon: AppIcon.area,
                leftToRight: true,
                label: <double>[
                  dimensions.width,
                  dimensions.height,
                  dimensions.depth,
                ].map(formatMeasure).join(' × '),
              ),
          ],
        ),
      ],
    );
  }
}

/// "4.8 (1,275 reviews)" from the listing's rating and its review count.
String _ratingSummary(Product product) =>
    '${formatRating(product.rating)} '
    '(${AppStrings.plural(AppStrings.detailsReviews, product.reviews.length)})';

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: _ratingSummary(product),
      leading: AppAssetImage(AppIcon.star, width: 24.r, height: 24.r),
      seeAllKey: AppKeys.reviewsSeeAll,
      onSeeAll: product.reviews.length > 1
          ? () => showReviewsSheet(context, product.reviews)
          : null,
    );
  }
}
