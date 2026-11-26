/// Build-time configuration.
///
/// The API host defaults to DummyJSON and can be overridden without touching
/// the code:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://dummyjson.com
/// ```
library;

abstract final class AppConfig {
  static const String defaultBaseUrl = 'https://dummyjson.com';

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// The API root without a trailing slash.
  static String get baseUrl => normalize(_rawBaseUrl);

  /// Whether [baseUrl] is an absolute http(s) URL. Checked by an assert at
  /// startup so a bad `--dart-define` fails immediately instead of making
  /// every request fail later.
  static bool get isConfigured => isValidBaseUrl(_rawBaseUrl);

  static String get misconfigurationMessage =>
      'API_BASE_URL "$_rawBaseUrl" is not an absolute http(s) URL.\n'
      'Pass a valid one, for example:\n'
      '  --dart-define=API_BASE_URL=$defaultBaseUrl';

  static String normalize(String raw) {
    final String trimmed = raw.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static bool isValidBaseUrl(String raw) {
    final Uri? uri = Uri.tryParse(raw.trim());
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }
}
