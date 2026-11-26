import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/app_strings.dart';
import '../theme/app_palette.dart';

/// A network image with a fixed size, the design's grey placeholder while
/// loading, and a calm fallback when the URL is missing or fails.
///
/// A broken image never throws or collapses the layout: the box keeps its
/// size either way.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? source = url?.trim();
    final Widget child = (source == null || source.isEmpty)
        ? const _ImageFallback()
        : CachedNetworkImage(
            imageUrl: source,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, _) => const _ImagePlaceholder(),
            errorWidget: (_, _, _) => const _ImageFallback(),
          );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.palette.imagePlaceholder);
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Semantics(
      label: AppStrings.t(AppStrings.stateImageUnavailable),
      image: true,
      child: ColoredBox(
        color: palette.imagePlaceholder,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.3,
            heightFactor: 0.3,
            child: FittedBox(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: palette.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
