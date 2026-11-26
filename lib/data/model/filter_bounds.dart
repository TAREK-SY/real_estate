import 'dart:math' as math;

import 'product.dart';
import 'product_filter.dart';

/// Price and weight spans of a result set, and the price histogram drawn
/// above the price slider.
///
/// DummyJSON prices run from under a dollar to tens of thousands, most of
/// them under $100, so the price slider and histogram use a log scale;
/// a linear one would squeeze nearly every item into the first bar.
class FilterBounds {
  FilterBounds._({
    required this.price,
    required this.weight,
    required List<int> histogram,
  }) : histogram = List<int>.unmodifiable(histogram);

  factory FilterBounds.from(List<Product> products) {
    final List<double> prices = <double>[
      for (final Product p in products)
        if (p.price.isFinite && p.price > 0) p.price,
    ];
    final List<double> weights = <double>[
      for (final Product p in products)
        if (p.weight != null && p.weight!.isFinite) p.weight!,
    ];
    final ValueRange? price = prices.isEmpty
        ? null
        : ValueRange(prices.reduce(math.min), prices.reduce(math.max));
    final List<int> histogram = List<int>.filled(bars, 0);
    if (price != null) {
      for (final double p in prices) {
        histogram[_bucket(_logPosition(p, price))]++;
      }
    }
    return FilterBounds._(
      price: price,
      weight: weights.isEmpty
          ? null
          : ValueRange(weights.reduce(math.min), weights.reduce(math.max)),
      histogram: histogram,
    );
  }

  static const int bars = 21;

  /// Lowest and highest positive price; `null` when no item has one.
  final ValueRange? price;

  /// Lightest and heaviest item; `null` when no item has a weight.
  final ValueRange? weight;

  /// Item count per log-scale price bucket, [bars] long.
  final List<int> histogram;

  /// Slider position (0..1) of [value] on the price scale.
  double pricePosition(double value) =>
      price == null ? 0 : _logPosition(value, price!).clamp(0.0, 1.0);

  /// Price at slider position [t]. The ends map exactly to the lowest and
  /// highest price, so rounding never drops the cheapest or dearest item.
  double priceAt(double t) {
    final ValueRange? span = price;
    if (span == null) return 0;
    if (t <= 0) return span.start;
    if (t >= 1) return span.end;
    final double lo = math.log(span.start);
    final double hi = math.log(span.end);
    return math.exp(lo + (hi - lo) * t);
  }

  static double _logPosition(double value, ValueRange span) {
    final double lo = math.log(span.start);
    final double hi = math.log(span.end);
    if (hi - lo < 1e-9) return 0;
    return (math.log(math.max(value, span.start)) - lo) / (hi - lo);
  }

  static int _bucket(double position) =>
      (position * bars).floor().clamp(0, bars - 1);
}
