import 'dart:io';

import '../config/app_config.dart';

typedef HostLookup = Future<List<InternetAddress>> Function(String host);

/// Whether the API host can be resolved, as a cheap connectivity check.
///
/// A DNS lookup answers "is there a usable network" better than an interface
/// check: a phone on Wi-Fi without internet still has an interface.
Future<bool> checkInternet({
  HostLookup lookup = InternetAddress.lookup,
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final String host = Uri.parse(AppConfig.baseUrl).host;
    final List<InternetAddress> result = await lookup(host).timeout(timeout);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on Object {
    return false;
  }
}
