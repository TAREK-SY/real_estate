import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// Reads `test/fixtures/<name>.json` as raw text.
String fixtureText(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

/// Reads `test/fixtures/<name>.json` as decoded JSON.
Object fixture(String name) => jsonDecode(fixtureText(name)) as Object;

/// A JSON response with the same headers the real API sends.
http.Response jsonResponse(String body, {int status = 200}) => http.Response(
  body,
  status,
  headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
);

/// Image cache that never touches the network or plugins: every image
/// resolves to the error widget.
///
/// `CachedNetworkImage` reaches path_provider and sqflite through the default
/// cache manager, which throws MissingPluginException under `flutter test`.
class OfflineCacheManager extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.error(StateError('no network in tests: $url'));
}
