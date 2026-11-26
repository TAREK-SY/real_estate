import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guards. Text checks are enough here because each rule is
/// about a declaration that cannot be hidden.
Iterable<(String, int, String)> _codeLines(String root) sync* {
  for (final FileSystemEntity entity in Directory(
    root,
  ).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String trimmed = lines[i].trimLeft();
      if (trimmed.startsWith('//')) continue;
      yield (entity.path.replaceAll(r'\', '/'), i + 1, lines[i]);
    }
  }
}

// Built from parts so this file does not match its own check.
const String _materialImport =
    'package:flutter/'
    'material.dart';

void main() {
  test('no widget state (GlobalKey, TextEditingController) in controllers', () {
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines(
        'lib/controller',
      ))
        if (code.contains('GlobalKey') ||
            code.contains('TextEditingController'))
          '$path:$line',
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Widget state belongs to the screen; pass values to controllers.',
    );
  });

  test('controllers release resources in onClose, not dispose', () {
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines(
        'lib/controller',
      ))
        if (RegExp(r'void\s+dispose\s*\(').hasMatch(code)) '$path:$line',
    ];
    expect(offenders, isEmpty, reason: 'GetX never calls dispose().');
  });

  test('no Get.put inside views', () {
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines('lib/view'))
        if (code.contains('Get.put(')) '$path:$line',
    ];
    expect(offenders, isEmpty, reason: 'Register controllers in a Binding.');
  });

  test('raw colors live only in the palette file', () {
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines('lib'))
        if (!path.endsWith('core/theme/app_palette.dart') &&
            (code.contains('Color(0x') || code.contains('Colors.')))
          '$path:$line',
    ];
    expect(offenders, isEmpty, reason: 'Read colors from context.palette.');
  });

  test('the deprecated Flutter material library is not imported', () {
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines('lib'))
        if (code.contains(_materialImport)) '$path:$line',
      for (final (String path, int line, String code) in _codeLines('test'))
        if (code.contains(_materialImport)) '$path:$line',
    ];
    expect(offenders, isEmpty, reason: 'Use package:material_ui instead.');
  });

  test('no hard-coded left/right in layout code', () {
    final RegExp fixed = RegExp(
      r'TextAlign\.(left|right)|EdgeInsets\.only\([^)]*\b(left|right):|'
      r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)|'
      r'\bPositioned\([^)]*\b(left|right):',
    );
    final List<String> offenders = <String>[
      for (final (String path, int line, String code) in _codeLines('lib'))
        if (fixed.hasMatch(code)) '$path:$line',
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Use start/end variants so the layout mirrors in Arabic.',
    );
  });

  test('no invisible bidi control characters in source or translations', () {
    final RegExp hidden = RegExp('[\u200E\u200F\u202A-\u202E\u2066-\u2069]');
    final List<String> offenders = <String>[
      for (final String root in <String>['lib', 'test', 'assets/l10n'])
        for (final FileSystemEntity entity in Directory(
          root,
        ).listSync(recursive: true))
          if (entity is File &&
              (entity.path.endsWith('.dart') ||
                  entity.path.endsWith('.json')) &&
              hidden.hasMatch(entity.readAsStringSync()))
            entity.path,
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Invisible direction marks change text order without a trace.',
    );
  });
}
