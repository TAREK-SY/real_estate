import 'package:intl/intl.dart';

/// Formats a USD price the same way in both languages: Western digits and a
/// leading `$`, with cents only when there are any ($1,899.99, $12,219).
///
/// Render the result with `LtrText` so the symbol and separators keep their
/// order inside an Arabic line.
String formatPrice(num price) {
  final bool whole = price == price.roundToDouble();
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: whole ? 0 : 2,
  ).format(price);
}

/// Formats a rating with one decimal (4.94 -> 4.9).
String formatRating(num rating) =>
    NumberFormat('0.0', 'en_US').format(rating.clamp(0, 5));

/// A measurement with at most one decimal and Western digits (2, 23.2).
/// Non-finite values come out as an empty string.
String formatMeasure(num value) {
  if (!value.isFinite) return '';
  return NumberFormat('0.#', 'en_US').format(value);
}
