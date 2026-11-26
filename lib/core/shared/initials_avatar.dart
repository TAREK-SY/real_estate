import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// A round avatar with up to two initials, for people without a photo
/// (DummyJSON reviewers). Decorative: the name is always shown beside it.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, required this.size});

  final String name;
  final double size;

  static String initialsOf(String name) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    return words
        .take(2)
        .map((String w) => String.fromCharCode(w.runes.first).toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size.r,
        height: size.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Text(
          initialsOf(name),
          maxLines: 1,
          style: appTextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: palette.primaryText,
          ),
        ),
      ),
    );
  }
}
