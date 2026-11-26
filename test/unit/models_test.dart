import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate/data/model/category.dart';
import 'package:real_estate/data/model/product.dart';
import 'package:real_estate/data/model/product_page.dart';
import 'package:real_estate/data/model/product_query.dart';
import 'package:real_estate/data/model/review.dart';

import '../helpers/test_doubles.dart';

void main() {
  group('Product', () {
    test('parses the real single-product response', () {
      final Product product = Product.tryParse(
        fixture('product') as Map<String, dynamic>,
      )!;
      expect(product.id, 14);
      expect(product.title, isNotEmpty);
      expect(product.price, greaterThan(0));
      expect(product.category, 'furniture');
      expect(product.rating, inInclusiveRange(0, 5));
      expect(product.images, isNotEmpty);
      expect(product.thumbnail, startsWith('https://'));
      expect(product.dimensions, isNotNull);
      expect(product.reviews, isNotEmpty);
      expect(product.reviews.first.reviewerName, isNotEmpty);
      expect(product.tags, isNotEmpty);
      expect(product.stock, isNotNull);
      expect(product.weight, isNotNull);
    });

    test('accepts numbers sent as strings', () {
      final Product product = Product.tryParse(<String, dynamic>{
        'id': '7',
        'title': 'Lamp',
        'price': '19.5',
        'rating': '4.2',
        'stock': '3',
      })!;
      expect(product.id, 7);
      expect(product.price, 19.5);
      expect(product.rating, 4.2);
      expect(product.stock, 3);
    });

    test('missing optional fields fall back to safe defaults', () {
      final Product product = Product.tryParse(<String, dynamic>{
        'id': 1,
        'title': 'Chair',
      })!;
      expect(product.price, 0);
      expect(product.brand, isNull);
      expect(product.thumbnail, isNull);
      expect(product.images, isEmpty);
      expect(product.reviews, isEmpty);
      expect(product.dimensions, isNull);
      expect(product.coverImage, isNull);
    });

    test('empty strings are treated as absent', () {
      final Product product = Product.tryParse(<String, dynamic>{
        'id': 1,
        'title': 'Chair',
        'brand': '  ',
        'thumbnail': '',
        'images': <dynamic>['', 'https://x/1.png', 5, null],
      })!;
      expect(product.brand, isNull);
      expect(product.images, <String>['https://x/1.png', '5']);
      expect(product.coverImage, 'https://x/1.png');
    });

    test('items without an id or a title are rejected', () {
      expect(Product.tryParse(<String, dynamic>{'title': 'x'}), isNull);
      expect(Product.tryParse(<String, dynamic>{'id': 1}), isNull);
      expect(
        Product.tryParse(<String, dynamic>{'id': 1, 'title': ' '}),
        isNull,
      );
    });

    test('incomplete dimensions are ignored', () {
      final Product product = Product.tryParse(<String, dynamic>{
        'id': 1,
        'title': 'Chair',
        'dimensions': <String, dynamic>{'width': 1, 'height': 2},
      })!;
      expect(product.dimensions, isNull);
    });
  });

  group('ProductPage', () {
    test('parses the real list response', () {
      final ProductPage page = ProductPage.tryParse(
        fixture('products_page') as Map<String, dynamic>,
      )!;
      expect(page.products, hasLength(2));
      expect(page.total, greaterThan(2));
      expect(page.skip, 0);
      expect(page.hasMore, isTrue);
    });

    test('skips broken items instead of failing the page', () {
      final ProductPage page = ProductPage.tryParse(<String, dynamic>{
        'products': <dynamic>[
          <String, dynamic>{'id': 1, 'title': 'A'},
          <String, dynamic>{'title': 'no id'},
          'junk',
        ],
        'total': 2,
        'skip': 0,
        'limit': 3,
      })!;
      expect(page.products.map((Product p) => p.id), <int>[1]);
    });

    test('hasMore is false on the last page and on an empty page', () {
      final ProductPage last = ProductPage.tryParse(<String, dynamic>{
        'products': <dynamic>[
          <String, dynamic>{'id': 1, 'title': 'A'},
        ],
        'total': 11,
        'skip': 10,
        'limit': 10,
      })!;
      expect(last.hasMore, isFalse);
      final ProductPage empty = ProductPage.tryParse(<String, dynamic>{
        'products': <dynamic>[],
        'total': 5,
      })!;
      expect(empty.hasMore, isFalse);
    });

    test('missing totals are derived from the items', () {
      final ProductPage page = ProductPage.tryParse(<String, dynamic>{
        'products': <dynamic>[
          <String, dynamic>{'id': 1, 'title': 'A'},
        ],
      })!;
      expect(page.total, 1);
      expect(page.limit, 1);
    });

    test('parsed lists cannot be changed by a caller', () {
      final ProductPage page = ProductPage.tryParse(
        fixture('products_page') as Map<String, dynamic>,
      )!;
      expect(() => page.products.clear(), throwsUnsupportedError);
      expect(() => page.products.first.images.clear(), throwsUnsupportedError);
      expect(() => page.products.first.tags.clear(), throwsUnsupportedError);
      final Product product = Product.tryParse(
        fixture('product') as Map<String, dynamic>,
      )!;
      expect(() => product.reviews.clear(), throwsUnsupportedError);
      expect(
        () => Category.listFrom(fixture('categories')).clear(),
        throwsUnsupportedError,
      );
    });

    test('a body without a products list is rejected', () {
      expect(ProductPage.tryParse(<String, dynamic>{'total': 1}), isNull);
      expect(ProductPage.tryParse(<String, dynamic>{'products': 'x'}), isNull);
    });
  });

  group('Category', () {
    test('parses the real categories response', () {
      final List<Category> categories = Category.listFrom(
        fixture('categories'),
      );
      expect(categories, hasLength(24));
      expect(categories.first.slug, 'beauty');
      expect(categories.first.name, 'Beauty');
    });

    test('accepts bare strings and skips items without a slug', () {
      final List<Category> categories = Category.listFrom(<dynamic>[
        'tops',
        <String, dynamic>{'name': 'No slug'},
        <String, dynamic>{'slug': 'vehicle'},
        42,
      ]);
      expect(categories.map((Category c) => c.slug), <String>[
        'tops',
        'vehicle',
      ]);
      expect(categories.last.name, 'vehicle');
    });

    test('equality is by slug', () {
      expect(
        const Category(slug: 'a', name: 'A'),
        const Category(slug: 'a', name: 'Other'),
      );
      expect(
        const Category(slug: 'a', name: 'A').hashCode,
        const Category(slug: 'a', name: 'Other').hashCode,
      );
      expect(
        <Category>{}
          ..add(const Category(slug: 'a', name: 'A'))
          ..add(const Category(slug: 'a', name: 'B')),
        hasLength(1),
      );
      expect(Category.listFrom('not a list'), isEmpty);
    });
  });

  group('Review', () {
    test('parses fields and tolerates a bad date', () {
      final Review review = Review.fromJson(<String, dynamic>{
        'rating': 5,
        'comment': ' Great ',
        'reviewerName': 'Ann',
        'date': 'not a date',
      });
      expect(review.rating, 5);
      expect(review.comment, 'Great');
      expect(review.date, isNull);
    });
  });

  group('ProductQuery', () {
    test('nextPage advances skip by limit and keeps the rest', () {
      const ProductQuery query = ProductQuery(
        search: 'a',
        categorySlug: 'tops',
        sort: ProductSort.ratingDesc,
        limit: 5,
        skip: 10,
      );
      final ProductQuery next = query.nextPage();
      expect(next.skip, 15);
      expect(next.limit, 5);
      expect(next.search, 'a');
      expect(next.categorySlug, 'tops');
      expect(next.sort, ProductSort.ratingDesc);
    });

    test('sort fields and orders', () {
      expect(ProductSort.none.field, isNull);
      expect(ProductSort.none.order, isNull);
      expect(ProductSort.priceAsc.field, 'price');
      expect(ProductSort.priceAsc.order, 'asc');
      expect(ProductSort.ratingDesc.field, 'rating');
      expect(ProductSort.titleAsc.order, 'asc');
      expect(ProductSort.titleAsc.field, 'title');
      expect(ProductSort.priceDesc.order, 'desc');
    });

    test('a blank search is not a search', () {
      expect(const ProductQuery(search: '   ').isSearch, isFalse);
      expect(
        const ProductQuery(search: '   ').toQueryParameters().containsKey('q'),
        isFalse,
      );
    });
  });
}
