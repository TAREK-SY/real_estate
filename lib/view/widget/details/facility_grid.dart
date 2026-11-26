import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// Four-column grid of facilities. DummyJSON has no amenities, so the
/// listing's tags fill it, each with the same tag icon.
class FacilityGrid extends StatelessWidget {
  const FacilityGrid({super.key, required this.labels});

  static const int columns = 4;

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, BoxConstraints constraints) {
        final double cell = constraints.maxWidth / columns;
        return Wrap(
          runSpacing: 20.h,
          children: <Widget>[
            for (final String label in labels)
              SizedBox(
                width: cell,
                child: FacilityItem(label: label),
              ),
          ],
        );
      },
    );
  }
}

class FacilityItem extends StatelessWidget {
  const FacilityItem({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Column(
      children: <Widget>[
        ExcludeSemantics(
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: palette.primaryFaint,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.tag, size: 28.r, color: palette.primary),
          ),
        ),
        SizedBox(height: 8.h),
        // Tags come from the API in English; laid out left to right so a
        // cut-off one ends in an ellipsis on the right.
        LtrText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: appTextStyle(fontSize: 14, height: 1.4, color: palette.black1),
        ),
      ],
    );
  }
}
