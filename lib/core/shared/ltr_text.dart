import 'package:material_ui/material_ui.dart';

/// Text that always reads left to right: prices, numbers, Latin codes.
///
/// Inside an Arabic layout a run like "$1,899.99" would otherwise be
/// reordered by the bidi algorithm. Only the text's own direction is fixed;
/// its position in the surrounding row still follows the layout direction.
class LtrText extends StatelessWidget {
  const LtrText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: _layoutAlign(Directionality.of(context)),
      ),
    );
  }

  // Under the forced LTR direction start means left even in an Arabic
  // layout, so start and end are swapped to keep following the layout.
  TextAlign _layoutAlign(TextDirection outer) {
    final TextAlign align = textAlign ?? TextAlign.start;
    if (outer == TextDirection.ltr) return align;
    return switch (align) {
      TextAlign.start => TextAlign.end,
      TextAlign.end => TextAlign.start,
      _ => align,
    };
  }
}
