import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;

import '../functions/check_internet.dart';
import 'status_request.dart';

/// A successful (2xx) response with its decoded JSON body.
class ApiResult {
  const ApiResult({required this.statusCode, required this.data});

  final int statusCode;

  /// The decoded body: a `Map<String, dynamic>` or a `List`.
  final Object data;

  Map<String, dynamic>? get map =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : null;

  List<dynamic>? get list => data is List ? data as List<dynamic> : null;
}

/// The only place that talks HTTP.
///
/// Every verb goes through [_send], which checks connectivity, applies the
/// timeout and turns transport errors and status codes into a
/// [StatusRequest]. The client and the connectivity check are injectable so
/// tests never touch the network.
class Crud {
  Crud({
    http.Client? client,
    Future<bool> Function()? connectivityCheck,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _checkConnectivity = connectivityCheck ?? checkInternet;

  final http.Client _client;
  final Future<bool> Function() _checkConnectivity;
  final Duration timeout;

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Accept': 'application/json',
  };

  Future<Either<StatusRequest, ApiResult>> getJson(
    String url, {
    Map<String, String>? query,
  }) {
    return _send(() => _client.get(_uri(url, query), headers: _jsonHeaders));
  }

  /// DummyJSON simulates writes: the response echoes the payload but nothing
  /// is stored on the server.
  Future<Either<StatusRequest, ApiResult>> postJson(
    String url,
    Map<String, dynamic> body,
  ) {
    return _send(
      () => _client.post(
        _uri(url, null),
        headers: <String, String>{
          ..._jsonHeaders,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Uri _uri(String url, Map<String, String>? query) {
    final Uri base = Uri.parse(url);
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: <String, String>{...base.queryParameters, ...query},
    );
  }

  Future<Either<StatusRequest, ApiResult>> _send(
    Future<http.Response> Function() issue,
  ) async {
    final http.Response response;
    try {
      if (!await _checkConnectivity()) {
        return const Left(StatusRequest.offlineFailure);
      }
    } on Object catch (e, st) {
      _log('connectivity check failed', e, st);
      return const Left(StatusRequest.offlineFailure);
    }

    try {
      response = await issue().timeout(timeout);
    } on TimeoutException {
      return const Left(StatusRequest.timeoutFailure);
    } on SocketException catch (e) {
      _log('socket error', e);
      return const Left(StatusRequest.offlineFailure);
    } on Object catch (e, st) {
      _log('request failed', e, st);
      return const Left(StatusRequest.serverFailure);
    }

    return _classify(response);
  }

  Either<StatusRequest, ApiResult> _classify(http.Response response) {
    final int code = response.statusCode;
    if (code < 200 || code >= 300) {
      _log('HTTP $code', response.request?.url ?? 'unknown url');
    }
    if (code == 404) return const Left(StatusRequest.notFoundFailure);
    if (code >= 500) return const Left(StatusRequest.serverFailure);
    if (code < 200 || code >= 300) return const Left(StatusRequest.failure);

    final Object? decoded = _decode(response);
    if (decoded is Map<String, dynamic> || decoded is List) {
      return Right(ApiResult(statusCode: code, data: decoded!));
    }
    return const Left(StatusRequest.unexpectedResponse);
  }

  Object? _decode(http.Response response) {
    try {
      // bodyBytes + utf8 rather than `body`: without a charset in the
      // Content-Type, `body` falls back to latin1 and mangles non-ASCII text.
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      _log('response is not JSON', e);
      return null;
    }
  }

  void _log(String message, Object error, [StackTrace? stack]) {
    developer.log(message, name: 'Crud', error: error, stackTrace: stack);
  }
}
