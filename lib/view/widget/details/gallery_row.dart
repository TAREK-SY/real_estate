import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/shared/app_network_image.dart';
import '../../../core/shared/ltr_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';

/// Up to three 118 photos in a row. When more remain, the third is darkened
/// with the count of the rest on it ("20+").
class GalleryRow extends StatelessWidget {
  const GalleryRow({super.key, required this.photos});

  static const int visible = 3;
  static const double size = 118;
  static const double radius = 10;

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    final List<String> shown = photos.take(visible).toList();
    final int more = photos.length - shown.length;
    // The design spreads three across the 390 content width.
    final double gap = (390 - visible * size) / (visible - 1);
    return Row(
      children: <Widget>[
        for (int i = 0; i < shown.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap.w),
          _Photo(url: shown[i], more: i == shown.length - 1 ? more : 0),
        ],
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.more});

  final String url;
  final int more;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(GalleryRow.radius.r);
    final Widget photo = AppNetworkImage(
      url: url,
      width: GalleryRow.size.w,
      height: GalleryRow.size.w,
      borderRadius: radius,
    );
    if (more <= 0) return photo;
    return Semantics(
      label: AppStrings.tArgs(AppStrings.detailsMoreImages, <String>['$more']),
      child: Stack(
        children: <Widget>[
          photo,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.photoScrim,
                borderRadius: radius,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: LtrText(
                    '$more+',
                    style: appTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: palette.white,
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
