import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a bundled image, choosing the renderer from the extension:
/// `SvgPicture.asset` for `.svg`, `Image.asset` otherwise.
///
/// [color] tints a monochrome asset; leave it null for multi-color art.
class AppAssetImage extends StatelessWidget {
  const AppAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.matchTextDirection = false,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final AlignmentGeometry alignment;
  final String? semanticLabel;

  /// Mirror directional art (arrows, chevrons) in right-to-left layouts.
  final bool matchTextDirection;

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        matchTextDirection: matchTextDirection,
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      matchTextDirection: matchTextDirection,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
