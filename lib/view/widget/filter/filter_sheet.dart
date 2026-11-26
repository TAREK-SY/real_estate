import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/explore/explore_controller.dart';
import '../../../core/class/handling_data_view.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/app_fonts.dart';
import '../../../core/constant/app_image_asset.dart';
import '../../../core/constant/app_keys.dart';
import '../../../core/functions/price_formatter.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/category_names.dart';
import '../../../core/shared/app_asset_image.dart';
import '../../../core/shared/app_divider.dart';
import '../../../core/shared/primary_button.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/model/category.dart';
import '../../../data/model/filter_bounds.dart';
import '../../../data/model/product_filter.dart';
import '../category_chip_row.dart';
import '../tap_area.dart';
import 'app_range_slider.dart';
import 'counter_stepper.dart';
import 'price_histogram.dart';

/// Opens the filter sheet over the Explore tab. Edits stay in the draft
/// until "Set Filter"; the back button closes without applying.
Future<void> showFilterSheet(BuildContext context) {
  final AppPalette palette = context.palette;
  Get.find<ExploreController>().openFilters();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.white,
    barrierColor: palette.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => const FilterSheet(),
  );
}

/// The filter sheet's content. Sections scroll between the fixed title row
/// and the "Set Filter" button; vertical gaps are the design gaps minus what
/// the 48 touch targets add around shorter elements.
class FilterSheet extends GetView<ExploreController> {
  const FilterSheet({super.key});

  static const double sheetHeight = 758;

  /// Space a 32 or 24 control's 48 target adds on each side.
  static const double backInset = (TapArea.minSize - 32) / 2;
  static const double stepperInset = (TapArea.minSize - 24) / 2;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return SizedBox(
      key: AppKeys.filterSheet,
      height: sheetHeight.h > maxHeight ? maxHeight : sheetHeight.h,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: 24.h),
        child: Column(
          children: <Widget>[
            SizedBox(height: (47 - backInset).h),
            const _SheetTitleRow(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  (32 - backInset).h,
                  20.w,
                  24.h,
                ),
                child: Obx(() => _sections(controller.draft.value)),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: PrimaryButton(
                key: AppKeys.filterApply,
                label: AppStrings.t(AppStrings.filterApply),
                onPressed: () {
                  controller.applyDraft();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sections(ProductFilter draft) {
    final StatusRequest status = controller.boundsStatus.value;
    final FilterBounds? bounds = controller.bounds.value;
    final ValueRange? weight = bounds?.weight;
    final bool weightReady =
        status == StatusRequest.success &&
        weight != null &&
        weight.end > weight.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(AppStrings.t(AppStrings.filterPrice)),
        SizedBox(height: 16.h),
        _PriceSection(status: status, bounds: bounds, draft: draft),
        SizedBox(height: 30.h),
        _SectionTitle(AppStrings.t(AppStrings.filterType)),
        SizedBox(height: 16.h),
        _TypeChips(
          categories: controller.categories.toList(),
          selected: draft.categories,
          onToggle: controller.toggleDraftCategory,
        ),
        SizedBox(height: 30.h),
        _SectionTitle(AppStrings.t(AppStrings.filterDetails)),
        SizedBox(height: (16 - stepperInset).h),
        CounterStepper(
          key: AppKeys.filterRatingStepper,
          label: AppStrings.t(AppStrings.filterMinRating),
          value: draft.minRating,
          max: ProductFilter.maxRating,
          onChanged: controller.setDraftMinRating,
        ),
        SizedBox(height: (14 - stepperInset).h),
        const AppDivider(),
        SizedBox(height: (14 - stepperInset).h),
        CounterStepper(
          key: AppKeys.filterStockStepper,
          label: AppStrings.t(AppStrings.filterMinStock),
          value: draft.minStock,
          max: ProductFilter.maxStock,
          step: ProductFilter.stockStep,
          onChanged: controller.setDraftMinStock,
        ),
        if (weightReady) ...<Widget>[
          SizedBox(height: (30 - stepperInset).h),
          _SectionTitle(AppStrings.t(AppStrings.filterWeight)),
          SizedBox(height: (16 - AppRangeSlider.inset).h),
          AppRangeSlider(
            key: AppKeys.filterWeightSlider,
            min: weight.start,
            max: weight.end,
            divisions: _divisions(weight),
            values: RangeValues(
              draft.weight?.start ?? weight.start,
              draft.weight?.end ?? weight.end,
            ),
            labelFamily: AppFonts.inter,
            format: _formatWeight,
            onChanged: (RangeValues v) =>
                controller.setDraftWeight(v.start, v.end),
          ),
        ],
      ],
    );
  }

  /// One stop per whole unit when the span is whole numbers.
  static int? _divisions(ValueRange span) {
    final double steps = span.end - span.start;
    return steps == steps.roundToDouble() && steps <= 100
        ? steps.round()
        : null;
  }

  static String _formatWeight(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);
}

class _SheetTitleRow extends GetView<ExploreController> {
  const _SheetTitleRow();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: TapArea.minSize,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              AppStrings.t(AppStrings.filterTitle),
              style: appTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: palette.black1,
              ),
            ),
          ),
          PositionedDirectional(
            start: (20 - FilterSheet.backInset).w,
            child: TapArea(
              key: AppKeys.filterClose,
              label: AppStrings.t(AppStrings.filterClose),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32.r,
                height: 32.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: AppAssetImage(
                  AppIcon.arrowLeft,
                  width: 20.r,
                  height: 20.r,
                  color: palette.black1,
                  matchTextDirection: true,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 20.w,
            child: InkWell(
              key: AppKeys.filterReset,
              onTap: controller.resetDraft,
              borderRadius: BorderRadius.circular(8.r),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TapArea.minSize,
                  minWidth: TapArea.minSize,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    AppStrings.t(AppStrings.filterReset),
                    style: appTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.8,
                      color: palette.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: appTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
          color: context.palette.black1,
        ),
      ),
    );
  }
}

/// Histogram with the price slider over its baseline. Positions are on the
/// log price scale of [FilterBounds].
class _PriceSection extends GetView<ExploreController> {
  const _PriceSection({
    required this.status,
    required this.bounds,
    required this.draft,
  });

  /// Bars are 58 tall; the slider track runs along their base.
  static const double barsHeight = 58;
  static const double sliderTop = barsHeight - AppRangeSlider.sliderHeight / 2;

  final StatusRequest status;
  final FilterBounds? bounds;
  final ProductFilter draft;

  @override
  Widget build(BuildContext context) {
    final FilterBounds? span = bounds;
    final ValueRange? price = span?.price;
    if (status != StatusRequest.success ||
        span == null ||
        price == null ||
        price.end <= price.start) {
      return SizedBox(
        height: 140.h,
        child: HandlingDataView(
          status: status == StatusRequest.success
              ? StatusRequest.empty
              : status,
          emptyMessageKey: AppStrings.filterRangesUnavailable,
          onRetry: controller.loadBounds,
          child: const SizedBox.shrink(),
        ),
      );
    }
    final ValueRange? selected = draft.price;
    String label(double t) {
      final double value = span.priceAt(t);
      return formatPrice(value < 10 ? value : value.roundToDouble());
    }

    return SizedBox(
      height: (sliderTop + AppRangeSlider.height).h,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            bottom: null,
            child: SizedBox(
              height: barsHeight.h,
              child: PriceHistogram(counts: span.histogram),
            ),
          ),
          Positioned.fill(
            top: sliderTop.h,
            child: AppRangeSlider(
              key: AppKeys.filterPriceSlider,
              min: 0,
              max: 1,
              values: RangeValues(
                selected == null ? 0 : span.pricePosition(selected.start),
                selected == null ? 1 : span.pricePosition(selected.end),
              ),
              format: label,
              onChanged: (RangeValues v) =>
                  controller.setDraftPrice(v.start, v.end),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-select category chips. Each chip keeps a 48 target; the run
/// spacing takes that back so the visible gap stays 10.
class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  static const double verticalPadding = 4;
  static const double chipHeight = 14 * 1.8 + 2 * verticalPadding;

  final List<Category> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final double inset = (TapArea.minSize - chipHeight.h) / 2;
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h - 2 * inset,
      children: <Widget>[
        for (final Category category in categories)
          CategoryChip(
            key: AppKeys.filterType(category.slug),
            label: categoryDisplayName(category),
            selected: selected.contains(category.slug),
            verticalPadding: verticalPadding,
            onTap: () => onToggle(category.slug),
          ),
      ],
    );
  }
}
