import 'package:material_ui/material_ui.dart';

/// A 48 x 48 touch target around a smaller icon, with a label for screen
/// readers. Disabled (and dimmed) when [onTap] is null.
class TapArea extends StatelessWidget {
  const TapArea({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.selected,
  });

  static const double minSize = 48;

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      // The child's own semantics (and its tap action) are excluded, so the
      // action is declared here.
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: minSize / 2,
        child: SizedBox.square(
          dimension: minSize,
          child: Center(
            child: Opacity(opacity: onTap == null ? 0.4 : 1, child: child),
          ),
        ),
      ),
    );
  }
}
