import 'package:easy_localization/easy_localization.dart' as ez;

/// Translation keys. Every key exists in both `assets/l10n/en.json` and
/// `assets/l10n/ar.json`; a test keeps the two files and this class in sync.
abstract final class AppStrings {
  static String t(String key) => ez.tr(key);

  /// [t] with positional `{}` arguments.
  static String tArgs(String key, List<String> args) => ez.tr(key, args: args);

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

  // Auth
  static const String authWelcome = 'auth.welcome';
  static const String authTitleLine1 = 'auth.titleLine1';
  static const String authTitleTo = 'auth.titleTo';
  static const String authTitleHighlight = 'auth.titleHighlight';
  static const String authSubtitle = 'auth.subtitle';
  static const String authGoogle = 'auth.google';
  static const String authGuestNotice = 'auth.guestNotice';

  // Home
  static const String homeGreetingMorning = 'home.greetingMorning';
  static const String homeGreetingAfternoon = 'home.greetingAfternoon';
  static const String homeGreetingEvening = 'home.greetingEvening';
  static const String homeGuestName = 'home.guestName';
  static const String homeAvatar = 'home.avatar';
  static const String homeNotifications = 'home.notifications';
  static const String homeSearchHint = 'home.searchHint';
  static const String homeFilters = 'home.filters';
  static const String homeFeatured = 'home.featured';
  static const String homeRecommendation = 'home.recommendation';
  static const String homeSeeAll = 'home.seeAll';
  static const String homeAllCategories = 'home.allCategories';
  static const String homeRating = 'home.rating';

  // Favorites
  static const String favoriteAdd = 'favorite.add';
  static const String favoriteRemove = 'favorite.remove';

  // Bottom navigation
  static const String navHome = 'nav.home';
  static const String navExplore = 'nav.explore';
  static const String navProfile = 'nav.profile';

  /// Prefix of the category name keys (`category.<slug>`).
  static const String categoryPrefix = 'category';
}
