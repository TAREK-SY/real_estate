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

/// Fake DummyJSON for the Home tab. Each path can be answered, failed, or
/// held until a test releases it.
class FakeHomeApi {
  /// Path (with `?skip=N` for later pages) -> response.
  final Map<String, http.Response> responses = <String, http.Response>{};

  /// Paths that wait on a completer before answering.
  final Map<String, Completer<void>> holds = <String, Completer<void>>{};

  final List<Uri> requests = <Uri>[];

  static String keyOf(Uri url) {
    final String skip = url.queryParameters['skip'] ?? '0';
    final bool sortedByRating = url.queryParameters['sortBy'] == 'rating';
    if (sortedByRating) return 'featured';
    return skip == '0' ? url.path : '${url.path}?skip=$skip';
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
}
