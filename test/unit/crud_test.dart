import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:real_estate/core/class/crud.dart';
import 'package:real_estate/core/class/status_request.dart';

import '../helpers/test_doubles.dart';

Crud _crud(
  MockClientHandler handler, {
  bool online = true,
  Duration timeout = const Duration(seconds: 15),
}) => Crud(
  client: MockClient(handler),
  connectivityCheck: () async => online,
  timeout: timeout,
);

void main() {
  group('Crud.getJson', () {
    test('returns the decoded map on 200', () async {
      final Crud crud = _crud((_) async => jsonResponse('{"a":1}'));
      final Either<StatusRequest, ApiResult> result = await crud.getJson(
        'https://api.test/x',
      );
      expect(result.isRight, isTrue);
      expect(result.right.map, <String, dynamic>{'a': 1});
      expect(result.right.statusCode, 200);
    });

    test('returns a decoded list on 200', () async {
      final Crud crud = _crud((_) async => jsonResponse('[1,2]'));
      final Either<StatusRequest, ApiResult> result = await crud.getJson(
        'https://api.test/x',
      );
      expect(result.right.list, <dynamic>[1, 2]);
      expect(result.right.map, isNull);
    });

    test('merges query parameters into the URL', () async {
      late Uri seen;
      final Crud crud = _crud((http.Request request) async {
        seen = request.url;
        return jsonResponse('{}');
      });
      await crud.getJson(
        'https://api.test/products?x=1',
        query: <String, String>{'limit': '10', 'q': 'a b'},
      );
      expect(seen.path, '/products');
      expect(seen.queryParameters, <String, String>{
        'x': '1',
        'limit': '10',
        'q': 'a b',
      });
    });

    test('decodes UTF-8 even without a charset header', () async {
      final Crud crud = _crud(
        (_) async => http.Response.bytes(utf8.encode('{"t":"منزل"}'), 200),
      );
      final Either<StatusRequest, ApiResult> result = await crud.getJson(
        'https://api.test/x',
      );
      expect(result.right.map!['t'], 'منزل');
    });

    test('offline: no request is sent', () async {
      int calls = 0;
      final Crud crud = _crud((_) async {
        calls++;
        return jsonResponse('{}');
      }, online: false);
      final Either<StatusRequest, ApiResult> result = await crud.getJson(
        'https://api.test/x',
      );
      expect(result.left, StatusRequest.offlineFailure);
      expect(calls, 0);
    });

    const Map<int, StatusRequest> codes = <int, StatusRequest>{
      404: StatusRequest.notFoundFailure,
      400: StatusRequest.failure,
      429: StatusRequest.failure,
      500: StatusRequest.serverFailure,
      503: StatusRequest.serverFailure,
      302: StatusRequest.failure,
    };
    for (final MapEntry<int, StatusRequest>(key: code, value: status)
        in codes.entries) {
      test('HTTP $code maps to ${status.name}', () async {
        final Crud crud = _crud(
          (_) async => jsonResponse('{"message":"x"}', status: code),
        );
        expect((await crud.getJson('https://api.test/x')).left, status);
      });
    }

    test('200 with a non-JSON body is an unexpected response', () async {
      final Crud crud = _crud(
        (_) async => http.Response('<html>maintenance</html>', 200),
      );
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.unexpectedResponse,
      );
    });

    test('200 with a JSON scalar is an unexpected response', () async {
      final Crud crud = _crud((_) async => jsonResponse('"ok"'));
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.unexpectedResponse,
      );
    });

    test('a slow server times out', () async {
      final Completer<http.Response> never = Completer<http.Response>();
      final Crud crud = _crud(
        (_) => never.future,
        timeout: const Duration(milliseconds: 20),
      );
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.timeoutFailure,
      );
    });

    test('a socket error is reported as offline', () async {
      final Crud crud = _crud(
        (_) async => throw const SocketException('Connection refused'),
      );
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.offlineFailure,
      );
    });

    test('a connectivity check that throws is reported as offline', () async {
      final Crud crud = Crud(
        client: MockClient((_) async => jsonResponse('{}')),
        connectivityCheck: () async => throw const FormatException('bad host'),
      );
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.offlineFailure,
      );
    });

    test('any other transport error is a server failure', () async {
      final Crud crud = _crud(
        (_) async => throw http.ClientException('connection closed'),
      );
      expect(
        (await crud.getJson('https://api.test/x')).left,
        StatusRequest.serverFailure,
      );
    });
  });

  group('Crud.postJson', () {
    test('sends a JSON body with a content type', () async {
      late http.Request seen;
      final Crud crud = _crud((http.Request request) async {
        seen = request;
        return jsonResponse('{"id":1}', status: 201);
      });
      final Either<StatusRequest, ApiResult> result = await crud.postJson(
        'https://api.test/carts/add',
        <String, dynamic>{'userId': 1},
      );
      expect(result.right.statusCode, 201);
      expect(seen.method, 'POST');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), <String, dynamic>{'userId': 1});
    });
  });
}
