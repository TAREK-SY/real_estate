import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final Map<String, String> out = <String, String>{};
  json.forEach((String key, dynamic value) {
    final String path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(_flatten(value, path));
    } else {
      out[path] = value.toString();
    }
  });
  return out;
}

Map<String, String> _load(String lang) => _flatten(
  jsonDecode(File('assets/l10n/$lang.json').readAsStringSync())
      as Map<String, dynamic>,
);

// A plural key is a map of forms; its `other` form stands for it.
bool _has(Map<String, String> strings, String key) =>
    strings.containsKey(key) || strings.containsKey('$key.other');

void main() {
  final Map<String, String> en = _load('en');
  final Map<String, String> ar = _load('ar');

  test('en.json and ar.json have the same keys', () {
    expect(en.keys.toSet().difference(ar.keys.toSet()), isEmpty);
    expect(ar.keys.toSet().difference(en.keys.toSet()), isEmpty);
  });

  test('no translation is empty', () {
    expect(
      en.entries.where((MapEntry<String, String> e) => e.value.trim().isEmpty),
      isEmpty,
    );
    expect(
      ar.entries.where((MapEntry<String, String> e) => e.value.trim().isEmpty),
      isEmpty,
    );
  });

  test('Arabic values are actually Arabic (except the brand name and the '
      'English language option, named in its own script)', () {
    const Set<String> latin = <String>{'appName', 'profile.english'};
    final RegExp arabic = RegExp(r'[\u0600-\u06FF]');
    final List<String> untranslated = <String>[
      for (final MapEntry<String, String>(:String key, :String value)
          in ar.entries)
        if (!latin.contains(key) && !arabic.hasMatch(value)) key,
    ];
    expect(untranslated, isEmpty);
  });

  test('every AppStrings key exists in both files', () {
    final String source = File('lib/core/localization/app_strings.dart')
        .readAsStringSync();
    final Iterable<String> keys = RegExp(
      r"static const String \w+ = '([^']+)';",
    ).allMatches(source).map((RegExpMatch m) => m.group(1)!);
    final List<String> missing = <String>[
      for (final String key in keys)
        if (key != 'category' && (!_has(en, key) || !_has(ar, key))) key,
    ];
    expect(keys, isNotEmpty);
    expect(missing, isEmpty);
  });

  test('every DummyJSON category slug has a translation', () {
    final List<dynamic> categories = jsonDecode(
      File('test/fixtures/categories.json').readAsStringSync(),
    ) as List<dynamic>;
    final List<String> missing = <String>[
      for (final dynamic c in categories)
        if (!en.containsKey('category.${c['slug']}') ||
            !ar.containsKey('category.${c['slug']}'))
          c['slug'] as String,
    ];
    expect(missing, isEmpty);
  });
}
