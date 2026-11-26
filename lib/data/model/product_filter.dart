import 'package:flutter/foundation.dart';

import 'product.dart';

/// Inclusive numeric range.
@immutable
class ValueRange {
  const ValueRange(this.start, this.end);

  final double start;
  final double end;

  bool contains(double value) => value >= start && value <= end;

  /// This range cut to [span]; `null` when nothing of it is left, or when
  /// it covers the whole span and so limits nothing.
  ValueRange? within(ValueRange span) {
    final double lo = start < span.start ? span.start : start;
    final double hi = end > span.end ? span.end : end;
    if (lo > hi || (lo <= span.start && hi >= span.end)) return null;
    return ValueRange(lo, hi);
  }

  @override
  bool operator ==(Object other) =>
      other is ValueRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ValueRange($start, $end)';
}

/// What the Explore results are narrowed to: categories from the chips or
/// the filter sheet, and the sheet's ranges and minimums.
@immutable
class ProductFilter {
  ProductFilter({
    Set<String> categories = const <String>{},
    this.price,
    this.minRating = 0,
    this.minStock = 0,
    this.weight,
  }) : categories = Set<String>.unmodifiable(categories);

  static final ProductFilter none = ProductFilter();

  static const int maxRating = 5;
  static const int maxStock = 100;
  static const int stockStep = 10;

  /// Category slugs; empty means every category.
  final Set<String> categories;

  /// `null` means any price.
  final ValueRange? price;
  final int minRating;
  final int minStock;

  /// `null` means any weight.
  final ValueRange? weight;

  /// Criteria DummyJSON cannot apply on its side.
  bool get hasLocalCriteria =>
      price != null || minRating > 0 || minStock > 0 || weight != null;

  bool get isEmpty => categories.isEmpty && !hasLocalCriteria;

  /// Whether the full result set has to be fetched and filtered on the
  /// device. The API pages a text search or a single category, but cannot
  /// combine the two, take several categories, or filter by price.
  bool needsLocalFiltering({required bool searching}) =>
      hasLocalCriteria ||
      categories.length > 1 ||
      (searching && categories.isNotEmpty);

  bool matches(Product product) {
    if (categories.isNotEmpty && !categories.contains(product.category)) {
      return false;
    }
    if (price != null && !price!.contains(product.price)) return false;
    if (product.rating < minRating) return false;
    if ((product.stock ?? 0) < minStock) return false;
    if (weight != null) {
      final double? value = product.weight;
      if (value == null || !weight!.contains(value)) return false;
    }
    return true;
  }

  List<Product> apply(List<Product> products) =>
      List<Product>.unmodifiable(products.where(matches));

  ProductFilter withCategories(Set<String> value) => _copy(categories: value);

  ProductFilter toggleCategory(String slug) {
    final Set<String> next = Set<String>.of(categories);
    if (!next.remove(slug)) next.add(slug);
    return _copy(categories: next);
  }

  ProductFilter withPrice(ValueRange? value) => _copy(price: () => value);

  ProductFilter withMinRating(int value) =>
      _copy(minRating: value.clamp(0, maxRating));

  ProductFilter withMinStock(int value) =>
      _copy(minStock: value.clamp(0, maxStock));

  ProductFilter withWeight(ValueRange? value) => _copy(weight: () => value);

  ProductFilter _copy({
    Set<String>? categories,
    ValueRange? Function()? price,
    int? minRating,
    int? minStock,
    ValueRange? Function()? weight,
  }) => ProductFilter(
    categories: categories ?? this.categories,
    price: price == null ? this.price : price(),
    minRating: minRating ?? this.minRating,
    minStock: minStock ?? this.minStock,
    weight: weight == null ? this.weight : weight(),
  );

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      setEquals(other.categories, categories) &&
      other.price == price &&
      other.minRating == minRating &&
      other.minStock == minStock &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(categories),
    price,
    minRating,
    minStock,
    weight,
  );
}
