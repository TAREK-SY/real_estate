import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Device storage that refuses list writes: returns false, or throws like a
/// failed platform channel. With [failures] set, only that many writes fail
/// and the later ones succeed; [written] holds the last stored list.
class FailingWritePrefs extends Fake implements SharedPreferences {
  FailingWritePrefs({this.throws = false, this.failures});

  final bool throws;
  final int? failures;
  int _writes = 0;
  List<String>? written;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _writes++;
    if (failures != null && _writes > failures!) {
      written = value;
      return true;
    }
    if (throws) throw PlatformException(code: 'write_failed');
    return false;
  }
}
