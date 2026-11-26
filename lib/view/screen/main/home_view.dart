import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/home/home_controller.dart';
import '../../../controller/main/main_controller.dart';
import '../../../core/class/handling_data_view.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/functions/greeting.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/shared/app_asset_image.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/model/product.dart';
import '../../widget/category_chip_row.dart';
import '../../widget/circle_icon_button.dart';
import '../../widget/featured_property_card.dart';
import '../../widget/product_results_sliver.dart';
import '../../widget/search_bar_button.dart';
import '../../widget/section_header.dart';

/// Home tab.
///
/// Vertical gaps are the design gaps minus what the 48 touch targets add
/// around shorter design elements (see [SectionHeader.inset]).
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Start loading the next grid page this far before the end.
  static const double loadMoreExtent = 400;

  @override
  Widget build(BuildContext context) {
    final MainController main = Get.find<MainController>();
    final double chipInset = (CategoryChipRow.height - CategoryChip.height) / 2;

    return SafeArea(
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) {
          if (n.metrics.axis == Axis.vertical &&
              n.metrics.extentAfter < loadMoreExtent) {
            controller.loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          color: context.palette.primary,
          onRefresh: controller.refreshAll,
          child: CustomScrollView(
            key: AppKeys.homeScroll,
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                sliver: SliverList.list(
                  children: <Widget>[
                    const _HomeHead(),
                    SizedBox(height: 22.h),
                    SearchBarButton(
                      onSearch: () => main.openExplore(ExploreEntry.search),
                      onFilter: () => main.openExplore(ExploreEntry.filters),
                    ),
                    SizedBox(height: (24 - SectionHeader.inset).h),
                    SectionHeader(
                      title: AppStrings.t(AppStrings.homeFeatured),
                      seeAllKey: AppKeys.featuredSeeAll,
                      onSeeAll: main.openExplore,
                    ),
                    SizedBox(height: (20 - SectionHeader.inset).h),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: _FeaturedRow()),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverList.list(
                  children: <Widget>[
                    SizedBox(height: (32 - SectionHeader.inset).h),
                    SectionHeader(
                      title: AppStrings.t(AppStrings.homeRecommendation),
                      seeAllKey: AppKeys.recommendationSeeAll,
                      onSeeAll: main.openExplore,
                    ),
                    SizedBox(height: (24 - SectionHeader.inset - chipInset).h),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(
                  () => CategoryChipRow(
                    categories: controller.categories.toList(),
                    selected: <String>{?controller.selectedCategory.value},
                    onSelected: controller.selectCategory,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: (24 - chipInset).h)),
              const _RecommendationGrid(),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHead extends StatelessWidget {
  const _HomeHead();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Row(
      children: <Widget>[
        ClipOval(
          child: AppAssetImage(
            AppImageAsset.avatarPlaceholder,
            width: 44.r,
            height: 44.r,
            fit: BoxFit.cover,
            semanticLabel: AppStrings.t(AppStrings.homeAvatar),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.t(greetingKey(DateTime.now())),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: palette.black3,
                ),
              ),
              Text(
                AppStrings.t(AppStrings.homeGuestName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: palette.black1,
                ),
              ),
            ],
          ),
        ),
        // Notifications are not part of this app; the bell stays visible
        // but disabled, without the unread dot.
        CircleIconButton(
          key: AppKeys.homeNotifications,
          icon: AppIcon.notification,
          label: AppStrings.t(AppStrings.homeNotifications),
          onPressed: null,
        ),
      ],
    );
  }
}

class _FeaturedRow extends GetView<HomeController> {
  const _FeaturedRow();

  @override
  Widget build(BuildContext context) {
    final double height = FeaturedPropertyCard.height.w;
    return Obx(() {
      final StatusRequest status = controller.featuredStatus.value;
      final List<Product> items = controller.featured.toList();
      return SizedBox(
        height: height,
        child: HandlingDataView(
          status: status,
          onRetry: controller.loadFeatured,
          child: ListView.separated(
            key: AppKeys.featuredList,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: 20.w),
            itemBuilder: (_, int index) =>
                FeaturedPropertyCard(product: items[index]),
          ),
        ),
      );
    });
  }
}

class _RecommendationGrid extends GetView<HomeController> {
  const _RecommendationGrid();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ProductResultsSliver(
        layout: ResultsLayout.grid,
        status: controller.status.value,
        products: controller.products.toList(),
        isLoadingMore: controller.isLoadingMore.value,
        loadMoreError: controller.loadMoreError.value,
        onRetry: controller.loadRecommendations,
        onRetryMore: controller.retryMore,
      ),
    );
  }
}
