import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import 'circle_icon_button.dart';
import 'tap_area.dart';
import 'titled_head_row.dart';

class ChoiceOption<T> {
  const ChoiceOption({required this.value, required this.label, this.leading});

  final T value;
  final String label;
  final Widget? leading;
}

/// A bottom sheet listing [options], the [selected] one ticked. Picking an
/// option closes the sheet and then calls [onSelected], so a change that
/// rebuilds the app (the language) runs with the sheet already gone.
Future<void> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceOption<T>> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  final AppPalette palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.white,
    barrierColor: palette.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (BuildContext sheetContext) => ChoiceSheet<T>(
      title: title,
      options: options,
      selected: selected,
      onSelected: (T value) {
        Navigator.of(sheetContext).pop();
        if (value != selected) onSelected(value);
      },
    ),
  );
}

class ChoiceSheet<T> extends StatelessWidget {
  const ChoiceSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return SafeArea(
      key: AppKeys.choiceSheet,
      top: false,
      minimum: EdgeInsets.only(bottom: 24.h),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TitledHeadRow(
              title: title,
              leading: CircleIconButton(
                icon: AppIcon.arrowLeft,
                label: AppStrings.t(AppStrings.profileCloseSheet),
                soft: true,
                matchTextDirection: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
              trailing: const SizedBox.square(dimension: TapArea.minSize),
            ),
            SizedBox(height: 16.h),
            for (final ChoiceOption<T> option in options)
              _OptionRow(
                key: AppKeys.choiceOption(option.value as Object),
                option: option,
                selected: option.value == selected,
                palette: palette,
                onTap: () => onSelected(option.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.option,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final ChoiceOption<T> option;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = option.leading;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 56.h),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[leading, SizedBox(width: 12.w)],
              Expanded(
                child: Text(
                  option.label,
                  style: appTextStyle(
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.4,
                    color: palette.black1,
                  ),
                ),
              ),
              if (selected)
                Icon(Iconsax.tick_circle, size: 24.r, color: palette.primary),
            ],
          ),
        ),
      ),
    );
  }
}
