import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// The design's primary button: fully rounded, primary fill, soft shadow.
///
/// Passing `null` to [onPressed] shows it disabled (muted, no shadow), so a
/// button never looks active without doing anything. The tap area is at
/// least 48 dp high even when the visual is shorter.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.verticalPadding = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double verticalPadding;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius radius = BorderRadius.circular(100.r);

    return Semantics(
      button: true,
      enabled: _enabled,
      // The spinner replaces the label while loading; keep the name.
      label: isLoading ? label : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _enabled ? palette.buttonShadow : null,
          ),
          child: Material(
            color: _enabled
                ? palette.primaryText
                : palette.primaryText.withValues(alpha: 0.4),
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: _enabled ? onPressed : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: verticalPadding.h,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: isLoading
                      ? SizedBox.square(
                          dimension: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.white,
                          ),
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: palette.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
