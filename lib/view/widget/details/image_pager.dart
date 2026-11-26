import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constant/app_keys.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/shared/app_network_image.dart';
import '../../../core/theme/app_palette.dart';

/// Full-width photo pager of the details header, with page dots near the
/// bottom edge. The dots are hidden for a single photo.
class ImagePager extends StatelessWidget {
  const ImagePager({
    super.key,
    required this.photos,
    required this.current,
    required this.onChanged,
    required this.height,
  });

  final List<String?> photos;
  final int current;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            key: AppKeys.detailsPager,
            itemCount: photos.length,
            onPageChanged: onChanged,
            itemBuilder: (_, int index) => Semantics(
              label: AppStrings.tArgs(AppStrings.detailsPhoto, <String>[
                '${index + 1}',
                '${photos.length}',
              ]),
              image: true,
              child: AppNetworkImage(
                url: photos[index],
                width: double.infinity,
                height: height,
              ),
            ),
          ),
          if (photos.length > 1)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 16.w,
              child: ExcludeSemantics(
                child: _Dots(count: photos.length, current: current),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 6.w),
            width: (i == current ? 32 : 8).w,
            height: 8.w,
            decoration: BoxDecoration(
              color: i == current ? palette.primary : palette.white,
              borderRadius: BorderRadius.circular(100.r),
              border: i == current
                  ? null
                  : Border.all(color: palette.pagerDotBorder, width: 0.5),
            ),
          ),
      ],
    );
  }
}
