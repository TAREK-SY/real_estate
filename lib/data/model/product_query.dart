/// Sort fields supported by `sortBy` on the products endpoints.
enum ProductSort {
  none,
  priceAsc,
  priceDesc,
  ratingDesc,
  titleAsc;

  String? get field => switch (this) {
    none => null,
    priceAsc || priceDesc => 'price',
    ratingDesc => 'rating',
    titleAsc => 'title',
  };

  String? get order => switch (this) {
    none => null,
    priceAsc || titleAsc => 'asc',
    priceDesc || ratingDesc => 'desc',
  };
}

/// What to load from the products API.
///
/// DummyJSON cannot combine a text search with a category in one call:
/// `/products/search` ignores categories. When [search] is set it wins and
/// [categorySlug] is left to the caller to apply on the results.
class ProductQuery {
  const ProductQuery({
    this.search = '',
    this.categorySlug,
    this.sort = ProductSort.none,
    this.limit = defaultLimit,
    this.skip = 0,
    this.fields = listFields,
  });

  /// Every product matching [search] (or of one category when there is no
  /// search) in one response, with the fields the local filters read.
  /// DummyJSON returns the whole set for `limit=0`.
  const ProductQuery.all({this.search = '', this.categorySlug})
    : sort = ProductSort.none,
      limit = 0,
      skip = 0,
      fields = filterFields;

  static const int defaultLimit = 10;

  /// Fields the list screens use; keeps responses small.
  static const List<String> listFields = <String>[
    'title',
    'price',
    'rating',
    'thumbnail',
    'images',
    'brand',
    'category',
  ];

  /// [listFields] plus what the filter sheet reads.
  static const List<String> filterFields = <String>[
    ...listFields,
    'stock',
    'weight',
  ];

  final String search;
  final String? categorySlug;
  final ProductSort sort;
  final int limit;
  final int skip;
  final List<String> fields;

  String get trimmedSearch => search.trim();

  bool get isSearch => trimmedSearch.isNotEmpty;

  ProductQuery nextPage() => ProductQuery(
    search: search,
    categorySlug: categorySlug,
    sort: sort,
    limit: limit,
    skip: skip + limit,
    fields: fields,
  );

  /// Query parameters shared by the list, search and category endpoints.
  Map<String, String> toQueryParameters() => <String, String>{
    'limit': '$limit',
    'skip': '$skip',
    'select': fields.join(','),
    if (isSearch) 'q': trimmedSearch,
    if (sort.field != null) 'sortBy': sort.field!,
    if (sort.order != null) 'order': sort.order!,
  };
}
