import 'package:easy_localization/easy_localization.dart' as ez;

/// Translation keys. Every key exists in both `assets/l10n/en.json` and
/// `assets/l10n/ar.json`; a test keeps the two files and this class in sync.
abstract final class AppStrings {
  static String t(String key) => ez.tr(key);

  static const String appName = 'appName';

  // Splash
  static const String splashTagline = 'splash.tagline';

  // Request states
  static const String stateLoading = 'state.loading';
  static const String stateEmpty = 'state.empty';
  static const String stateOffline = 'state.offline';
  static const String stateTimeout = 'state.timeout';
  static const String stateServer = 'state.server';
  static const String stateNotFound = 'state.notFound';
  static const String stateUnexpected = 'state.unexpected';
  static const String stateFailure = 'state.failure';
  static const String stateRetry = 'state.retry';
  static const String stateImageUnavailable = 'state.imageUnavailable';

  // Not found screen
  static const String notFoundTitle = 'notFound.title';
  static const String notFoundSubtitle = 'notFound.subtitle';
  static const String notFoundAction = 'notFound.action';

  /// Prefix of the category name keys (`category.<slug>`).
  static const String categoryPrefix = 'category';
}
