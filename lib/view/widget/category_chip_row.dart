import 'dart:math' as math;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/category_names.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/util/app_dimensions.dart';
import '../../data/model/category.dart';

/// Category chips, "All" first, scrolling horizontally. Every selected
/// category is highlighted; tapping a chip selects that one alone.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  /// The row is 48 tall (touch target) around 41 tall chips.
  static const double height = 48;

  /// A chip outgrows the 48 row on large screens with large text.
  static double heightOf(BuildContext context) => math.max(
    height,
    MediaQuery.textScalerOf(context).scale(size(CategoryChip.fontSize)) *
            CategoryChip.lineHeight +
        2 * CategoryChip.rowPadding.h,
  );

  final List<Category> categories;

  /// Selected slugs; empty is "All".
  final Set<String> selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightOf(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (BuildContext context, int index) {
          final Category? category = index == 0 ? null : categories[index - 1];
          return CategoryChip(
            key: AppKeys.categoryChip(category?.slug ?? 'all'),
            label: category == null
                ? AppStrings.t(AppStrings.homeAllCategories)
                : categoryDisplayName(category),
            selected: category == null
                ? selected.isEmpty
                : selected.contains(category.slug),
            onTap: () => onSelected(category?.slug),
          );
        },
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.verticalPadding = rowPadding,
  });

  static const double fontSize = 14;
  static const double lineHeight = 1.8;
  static const double rowPadding = 8;

  /// Height of a chip with the default padding.
  static const double height = fontSize * lineHeight + 2 * rowPadding;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 8 in the chip rows, 4 in the filter sheet.
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(30.r);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: verticalPadding.h,
              ),
              decoration: BoxDecoration(
                color: selected ? palette.primaryText : palette.primaryFaint,
                borderRadius: radius,
                border: selected
                    ? null
                    : Border.all(color: palette.primarySoft),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: appTextStyle(
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  height: lineHeight,
                  color: selected ? palette.white : palette.black1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
