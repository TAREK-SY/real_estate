import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate/data/model/filter_bounds.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/data/model/product_filter.dart';
import 'package:real_estate/data/model/product_query.dart';

Product _p(
  int id, {
  String category = 'beauty',
  double price = 10,
  double rating = 4,
  int? stock = 10,
  double? weight = 1,
}) => Product(
  id: id,
  title: 'P$id',
  price: price,
  category: category,
  rating: rating,
  stock: stock,
  weight: weight,
);

void main() {
  group('ProductFilter', () {
    test('an empty filter matches everything and needs no local work', () {
      final ProductFilter f = ProductFilter.none;
      expect(f.isEmpty, isTrue);
      expect(f.matches(_p(1, stock: null, weight: null)), isTrue);
      expect(f.needsLocalFiltering(searching: true), isFalse);
      expect(f.needsLocalFiltering(searching: false), isFalse);
    });

    test('the API pages a search alone or one category alone', () {
      final ProductFilter one = ProductFilter(categories: const <String>{'a'});
      expect(one.needsLocalFiltering(searching: false), isFalse);
      expect(one.needsLocalFiltering(searching: true), isTrue);
      expect(
        ProductFilter(categories: const <String>{'a', 'b'})
            .needsLocalFiltering(searching: false),
        isTrue,
      );
      for (final ProductFilter f in <ProductFilter>[
        ProductFilter.none.withPrice(const ValueRange(1, 2)),
        ProductFilter.none.withMinRating(3),
        ProductFilter.none.withMinStock(10),
        ProductFilter.none.withWeight(const ValueRange(1, 2)),
      ]) {
        expect(f.hasLocalCriteria, isTrue);
        expect(f.needsLocalFiltering(searching: false), isTrue);
      }
    });

    test('each criterion narrows the matches', () {
      final ProductFilter f = ProductFilter(
        categories: const <String>{'beauty', 'laptops'},
        price: const ValueRange(10, 100),
        minRating: 4,
        minStock: 10,
        weight: const ValueRange(1, 5),
      );
      expect(f.matches(_p(1)), isTrue);
      expect(f.matches(_p(2, category: 'furniture')), isFalse);
      expect(f.matches(_p(3, price: 9.99)), isFalse);
      expect(f.matches(_p(4, price: 100)), isTrue, reason: 'inclusive end');
      expect(f.matches(_p(5, rating: 3.99)), isFalse);
      expect(f.matches(_p(6, stock: 9)), isFalse);
      expect(f.matches(_p(7, stock: null)), isFalse, reason: 'no stock is 0');
      expect(f.matches(_p(8, weight: 6)), isFalse);
      expect(f.matches(_p(9, weight: null)), isFalse);
    });

    test('apply keeps the order and returns an unmodifiable list', () {
      final List<Product> out = ProductFilter.none.withMinRating(4).apply(
        <Product>[_p(1, rating: 5), _p(2, rating: 1), _p(3)],
      );
      expect(out.map((Product p) => p.id), <int>[1, 3]);
      expect(() => out.add(_p(4)), throwsUnsupportedError);
    });

    test('toggling a category adds then removes it', () {
      final ProductFilter on = ProductFilter.none.toggleCategory('a');
      expect(on.categories, <String>{'a'});
      expect(on.toggleCategory('a').categories, isEmpty);
      expect(() => on.categories.add('b'), throwsUnsupportedError);
    });

    test('minimums are clamped to their ranges', () {
      expect(ProductFilter.none.withMinRating(9).minRating, 5);
      expect(ProductFilter.none.withMinRating(-1).minRating, 0);
      expect(ProductFilter.none.withMinStock(500).minStock, 100);
    });

    test('ranges can be cleared again', () {
      final ProductFilter f = ProductFilter.none
          .withPrice(const ValueRange(1, 2))
          .withWeight(const ValueRange(3, 4));
      expect(f.withPrice(null).price, isNull);
      expect(f.withPrice(null).weight, const ValueRange(3, 4));
      expect(f.withWeight(null).weight, isNull);
    });

    test('equality ignores category order', () {
      final ProductFilter a = ProductFilter(
        categories: const <String>{'x', 'y'},
      );
      final ProductFilter b = ProductFilter(
        categories: const <String>{'y', 'x'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.withMinStock(10), isFalse);
      expect(const ValueRange(1, 2).toString(), contains('1'));
      expect(const ValueRange(1, 2).hashCode, const ValueRange(1, 2).hashCode);
    });
  });

  group('FilterBounds', () {
    test('no items gives no spans and empty bars', () {
      final FilterBounds b = FilterBounds.from(const <Product>[]);
      expect(b.price, isNull);
      expect(b.weight, isNull);
      expect(b.histogram, hasLength(FilterBounds.bars));
      expect(b.histogram.every((int c) => c == 0), isTrue);
      expect(b.priceAt(0.5), 0);
      expect(b.pricePosition(10), 0);
    });

    test('spans skip free, broken and missing values', () {
      final FilterBounds b = FilterBounds.from(<Product>[
        _p(1, price: 0, weight: null),
        _p(2, price: double.nan),
        _p(3, price: 2, weight: 4),
        _p(4, price: 2000, weight: 9),
      ]);
      expect(b.price, const ValueRange(2, 2000));
      expect(b.weight, const ValueRange(1, 9));
      expect(b.histogram.reduce((int a, int c) => a + c), 2);
      expect(b.histogram.first, 1);
      expect(b.histogram.last, 1);
    });

    test('the price scale is logarithmic and its ends are exact', () {
      final FilterBounds b = FilterBounds.from(<Product>[
        _p(1, price: 1),
        _p(2, price: 10),
        _p(3, price: 100),
      ]);
      expect(b.priceAt(0), 1);
      expect(b.priceAt(1), 100);
      expect(b.priceAt(0.5), closeTo(10, 1e-9));
      expect(b.pricePosition(10), closeTo(0.5, 1e-9));
      expect(b.pricePosition(1000), 1);
      expect(b.histogram[FilterBounds.bars ~/ 2], 1);
      expect(() => b.histogram[0] = 5, throwsUnsupportedError);
    });

    test('a single price does not divide by zero', () {
      final FilterBounds b = FilterBounds.from(<Product>[
        _p(1, price: 5),
        _p(2, price: 5),
      ]);
      expect(b.price, const ValueRange(5, 5));
      expect(b.pricePosition(5), 0);
      expect(b.histogram.first, 2);
    });
  });

  group('ProductQuery.all', () {
    test('asks for every item with the filter fields', () {
      const ProductQuery q = ProductQuery.all(search: ' lamp ');
      final Map<String, String> params = q.toQueryParameters();
      expect(params['limit'], '0');
      expect(params['q'], 'lamp');
      expect(params['select'], contains('stock'));
      expect(params['select'], contains('weight'));
      expect(params.containsKey('sortBy'), isFalse);
    });

    test('later pages keep the selected fields', () {
      const ProductQuery q = ProductQuery(fields: <String>['title']);
      expect(q.nextPage().toQueryParameters()['select'], 'title');
      expect(q.nextPage().skip, ProductQuery.defaultLimit);
    });
  });
}
