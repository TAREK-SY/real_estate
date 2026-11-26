import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Loads the real translation files from disk, so screen tests render the
/// actual English and Arabic text instead of raw keys.
///
/// The asset bundle is not available under `flutter test`. The future must
/// be a regular one: easy_localization waits on loaders with `Future.wait`,
/// which never completes for a `SynchronousFuture`.
class DiskAssetLoader extends AssetLoader {
  const DiskAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final File file = File('$path/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}
