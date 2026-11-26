import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'test_doubles.dart';

/// A products page with listings [ids] (titled `Listing <id>`).
String pageJson(List<int> ids, {int? total, int skip = 0}) =>
    jsonEncode(<String, Object>{
      'products': <Map<String, Object>>[
        for (final int id in ids)
          <String, Object>{
            'id': id,
            'title': 'Listing $id',
            'price': 1000 + id,
            'rating': 4.5,
            'thumbnail': 'https://example.test/$id.png',
            'brand': 'Brand $id',
            'category': 'furniture',
          },
      ],
      'total': total ?? ids.length,
      'skip': skip,
      'limit': ids.length,
    });

/// A page of full listings, for the local filters.
String listingsJson(List<Map<String, Object>> items, {int? total}) =>
    jsonEncode(<String, Object>{
      'products': items,
      'total': total ?? items.length,
      'skip': 0,
      'limit': items.length,
    });

Map<String, Object> listing(
  int id, {
  required String category,
  required double price,
  double rating = 4.5,
  int stock = 10,
  double weight = 1,
}) => <String, Object>{
  'id': id,
  'title': 'Listing $id',
  'price': price,
  'rating': rating,
  'stock': stock,
  'weight': weight,
  'thumbnail': 'https://example.test/$id.png',
  'brand': 'Brand $id',
  'category': category,
};

/// Six listings across four categories, prices from $5.99 to $1,499.99 and
/// weights 1 to 10.
final List<Map<String, Object>> exploreListings = <Map<String, Object>>[
  listing(1, category: 'beauty', price: 5.99, rating: 4.9, stock: 5),
  listing(
    2,
    category: 'beauty',
    price: 19.99,
    rating: 3.2,
    stock: 50,
    weight: 2,
  ),
  listing(3, category: 'furniture', price: 299.99, stock: 20, weight: 8),
  listing(
    4,
    category: 'laptops',
    price: 1499.99,
    rating: 4,
    stock: 0,
    weight: 3,
  ),
  listing(
    5,
    category: 'furniture',
    price: 89,
    rating: 2.5,
    stock: 80,
    weight: 10,
  ),
  listing(
    6,
    category: 'smartphones',
    price: 999.99,
    rating: 4.7,
    stock: 95,
    weight: 2,
  ),
];

/// Fake DummyJSON for the Home tab. Each path can be answered, failed, or
/// held until a test releases it.
class FakeHomeApi {
  /// Path (with `?skip=N` for later pages) -> response.
  final Map<String, http.Response> responses = <String, http.Response>{};

  /// Paths that wait on a completer before answering.
  final Map<String, Completer<void>> holds = <String, Completer<void>>{};

  final List<Uri> requests = <Uri>[];

  /// `featured` for the top-rated row; otherwise the path, with `q=<text>`,
  /// `all` (for `limit=0`) and `skip=<n>` (after the first page) appended.
  static String keyOf(Uri url) {
    final Map<String, String> q = url.queryParameters;
    if (q['sortBy'] == 'rating') return 'featured';
    final List<String> parts = <String>[
      if (q['q'] != null) 'q=${q['q']}',
      if (q['limit'] == '0') 'all',
      if ((q['skip'] ?? '0') != '0') 'skip=${q['skip']}',
    ];
    return parts.isEmpty ? url.path : '${url.path}?${parts.join('&')}';
  }

  Future<http.Response> handle(http.Request request) async {
    requests.add(request.url);
    final String key = keyOf(request.url);
    final Completer<void>? hold = holds[key];
    if (hold != null) await hold.future;
    return responses[key] ?? jsonResponse('{}', status: 404);
  }

  /// Featured, categories and a first grid page of two listings.
  static FakeHomeApi standard() => FakeHomeApi()
    ..responses['featured'] = jsonResponse(pageJson(<int>[1, 2]))
    ..responses['/products/categories'] = jsonResponse(
      fixtureText('categories'),
    )
    ..responses['/products'] = jsonResponse(pageJson(<int>[11, 12]));

  /// [standard] plus the full set (`limit=0`) used by the filter sheet and
  /// the local filters.
  static FakeHomeApi explore() => standard()
    ..responses['/products?all'] = jsonResponse(listingsJson(exploreListings));
}
