import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/explore/explore_controller.dart';
import '../../../controller/main/main_controller.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widget/category_chip_row.dart';
import '../../widget/circle_icon_button.dart';
import '../../widget/filter/filter_sheet.dart';
import '../../widget/product_results_sliver.dart';
import '../../widget/search_field_frame.dart';
import '../../widget/tap_area.dart';
import '../../widget/titled_head_row.dart';

/// Explore tab: search, category chips, the filter sheet and the results as
/// a list or a grid.
///
/// Stateful for what belongs to the widget: the text field's controller and
/// focus, and the scroll position, which goes back to the top for each new
/// set of results.
class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  /// Start loading the next page this far before the end.
  static const double loadMoreExtent = 400;

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  late final Worker _entryWorker;
  late final Worker _resultsWorker;

  ExploreController get _explore => Get.find<ExploreController>();
  MainController get _main => Get.find<MainController>();

  @override
  void initState() {
    super.initState();
    _text.text = _explore.search.value;
    _entryWorker = ever<ExploreEntry?>(_main.exploreEntry, (_) => _onEntry());
    _resultsWorker = ever<int>(_explore.results.generation, (_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onEntry());
  }

  @override
  void dispose() {
    _entryWorker.dispose();
    _resultsWorker.dispose();
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Acted on after the next frame: the tab is hidden (and cannot take
  // focus) until the shell has rebuilt with Explore selected.
  void _onEntry() {
    if (!mounted) return;
    final ExploreEntry? entry = _main.takeExploreEntry();
    if (entry == null || entry == ExploreEntry.browse) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (entry == ExploreEntry.search) {
        _focus.requestFocus();
      } else {
        _openFilters();
      }
    });
  }

  void _openFilters() {
    _focus.unfocus();
    showFilterSheet(context);
  }

  void _back() {
    _focus.unfocus();
    _main.select(MainTab.home);
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController c = _explore;
    final double chipInset = (CategoryChipRow.height - CategoryChip.height) / 2;
    final double headInset = (TapArea.minSize - 44) / 2;
    const double foundInset = (TapArea.minSize - 24) / 2;

    return SafeArea(
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) {
          if (n.metrics.axis == Axis.vertical &&
              n.metrics.extentAfter < ExploreView.loadMoreExtent) {
            c.results.loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          key: AppKeys.exploreScroll,
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, (16 - headInset).h, 20.w, 0),
              sliver: SliverList.list(
                children: <Widget>[
                  TitledHeadRow(
                    title: AppStrings.t(AppStrings.exploreTitle),
                    leading: CircleIconButton(
                      key: AppKeys.exploreBack,
                      icon: AppIcon.arrowLeft,
                      label: AppStrings.t(AppStrings.exploreBack),
                      soft: true,
                      matchTextDirection: true,
                      onPressed: _back,
                    ),
                    // Notifications are not part of this app (as on Home).
                    trailing: CircleIconButton(
                      key: AppKeys.exploreNotifications,
                      icon: AppIcon.notification,
                      label: AppStrings.t(AppStrings.homeNotifications),
                      onPressed: null,
                    ),
                  ),
                  SizedBox(height: (24 - headInset).h),
                  _SearchField(
                    text: _text,
                    focus: _focus,
                    onFilter: _openFilters,
                  ),
                  SizedBox(height: (24 - chipInset).h),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(
                () => CategoryChipRow(
                  categories: c.categories.toList(),
                  selected: c.filter.value.categories,
                  onSelected: c.selectCategory,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                (32 - chipInset - foundInset).h,
                20.w,
                (24 - foundInset).h,
              ),
              sliver: const SliverToBoxAdapter(child: _FoundRow()),
            ),
            Obx(
              () => ProductResultsSliver(
                layout: c.layout.value == ExploreLayout.grid
                    ? ResultsLayout.grid
                    : ResultsLayout.list,
                status: c.results.status.value,
                products: c.results.products.toList(),
                isLoadingMore: c.results.isLoadingMore.value,
                loadMoreError: c.results.loadMoreError.value,
                emptyMessageKey: AppStrings.exploreNoResults,
                onRetry: c.retry,
                onRetryMore: c.results.retryMore,
                onOpen: Get.find<MainController>().openDetails,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends GetView<ExploreController> {
  const _SearchField({
    required this.text,
    required this.focus,
    required this.onFilter,
  });

  final TextEditingController text;
  final FocusNode focus;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return SearchFieldFrame(
      filterKey: AppKeys.exploreFilter,
      onFilter: onFilter,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: SearchFieldFrame.iconInset.w,
        ),
        child: Row(
          children: <Widget>[
            const SearchFieldIcon(),
            SizedBox(width: SearchFieldFrame.iconGap.w),
            Expanded(
              child: TextField(
                key: AppKeys.exploreSearchField,
                controller: text,
                focusNode: focus,
                textInputAction: TextInputAction.search,
                cursorColor: palette.primary,
                onChanged: controller.onSearchChanged,
                onSubmitted: controller.submitSearch,
                style: appTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: palette.black1,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: AppStrings.t(AppStrings.homeSearchHint),
                  hintStyle: appTextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: palette.black3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Found N" and the list/grid switch.
class _FoundRow extends GetView<ExploreController> {
  const _FoundRow();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Obx(() {
      final StatusRequest status = controller.results.status.value;
      final bool grid = controller.layout.value == ExploreLayout.grid;
      final String found = switch (status) {
        StatusRequest.success || StatusRequest.empty => AppStrings.plural(
          AppStrings.exploreFound,
          controller.results.total.value,
        ),
        _ => '',
      };
      return Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                found,
                key: AppKeys.exploreFound,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: palette.black1,
                ),
              ),
            ),
          ),
          // Overhangs the content edge by the target's padding, so the
          // icon lines up with the cards' edge.
          Transform.translate(
            offset: Offset(
              (Directionality.of(context) == TextDirection.rtl ? -12 : 12).w,
              0,
            ),
            child: TapArea(
              key: AppKeys.exploreLayoutToggle,
              label: AppStrings.t(
                grid ? AppStrings.exploreShowList : AppStrings.exploreShowGrid,
              ),
              onTap: controller.toggleLayout,
              child: Icon(
                // The plain names are the bold set; `_copy` is the linear one the
                // design's vuesax icons use.
                grid ? Iconsax.row_vertical_copy : Iconsax.element_3_copy,
                size: 24.r,
                color: palette.black1,
              ),
            ),
          ),
        ],
      );
    });
  }
}
