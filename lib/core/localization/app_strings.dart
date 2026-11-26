import 'package:easy_localization/easy_localization.dart' as ez;

/// Translation keys. Every key exists in both `assets/l10n/en.json` and
/// `assets/l10n/ar.json`; a test keeps the two files and this class in sync.
abstract final class AppStrings {
  static String t(String key) => ez.tr(key);

  /// Plural form of [key] for [count] (`zero`, `one`, `two`, `few`, `many`,
  /// `other`), with the count in place of `{}`.
  static String plural(String key, int count) => ez.plural(key, count);

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

  // Explore
  static const String exploreTitle = 'explore.title';
  static const String exploreBack = 'explore.back';
  static const String exploreShowGrid = 'explore.showGrid';
  static const String exploreShowList = 'explore.showList';
  static const String exploreNoResults = 'explore.noResults';

  /// Plural map: use [plural].
  static const String exploreFound = 'explore.found';

  // Filter sheet
  static const String filterTitle = 'filter.title';
  static const String filterClose = 'filter.close';
  static const String filterReset = 'filter.reset';
  static const String filterPrice = 'filter.price';
  static const String filterType = 'filter.type';
  static const String filterDetails = 'filter.details';
  static const String filterMinRating = 'filter.minRating';
  static const String filterMinStock = 'filter.minStock';
  static const String filterWeight = 'filter.weight';
  static const String filterApply = 'filter.apply';
  static const String filterDecrease = 'filter.decrease';
  static const String filterIncrease = 'filter.increase';
  static const String filterRangesUnavailable = 'filter.rangesUnavailable';

  // Favorites
  static const String favoriteAdd = 'favorite.add';
  static const String favoriteRemove = 'favorite.remove';

  // Bottom navigation
  static const String navHome = 'nav.home';
  static const String navExplore = 'nav.explore';
  static const String navProfile = 'nav.profile';

  // Details
  static const String detailsBack = 'details.back';
  static const String detailsShare = 'details.share';
  static const String detailsPhoto = 'details.photo';

  /// Plural map: use [plural].
  static const String detailsReviews = 'details.reviews';
  static const String detailsStock = 'details.stock';
  static const String detailsWeight = 'details.weight';
  static const String detailsOverview = 'details.overview';
  static const String detailsFacilities = 'details.facilities';
  static const String detailsGallery = 'details.gallery';
  static const String detailsMoreImages = 'details.moreImages';
  static const String detailsReviewsTitle = 'details.reviewsTitle';
  static const String detailsPrice = 'details.price';
  static const String detailsBook = 'details.book';
  static const String detailsBookingSent = 'details.bookingSent';
  static const String detailsLoadFailed = 'details.loadFailed';

  // Relative time
  static const String timeJustNow = 'time.justNow';

  /// Plural map: use [plural].
  static const String timeMinutes = 'time.minutes';

  /// Plural map: use [plural].
  static const String timeHours = 'time.hours';

  /// Plural map: use [plural].
  static const String timeDays = 'time.days';

  /// Plural map: use [plural].
  static const String timeMonths = 'time.months';

  /// Plural map: use [plural].
  static const String timeYears = 'time.years';

  // Profile
  static const String profileTitle = 'profile.title';
  static const String profileEditPhoto = 'profile.editPhoto';
  static const String profileMyBooking = 'profile.myBooking';
  static const String profilePayments = 'profile.payments';
  static const String profileProfile = 'profile.profile';
  static const String profileNotification = 'profile.notification';
  static const String profileSecurity = 'profile.security';
  static const String profileLanguage = 'profile.language';
  static const String profileColors = 'profile.colors';
  static const String profileHelpCenter = 'profile.helpCenter';
  static const String profileInviteFriends = 'profile.inviteFriends';
  static const String profileLogout = 'profile.logout';
  static const String profileEnglish = 'profile.english';
  static const String profileArabic = 'profile.arabic';
  static const String profilePaletteOriginal = 'profile.paletteOriginal';
  static const String profilePalettePurple = 'profile.palettePurple';
  static const String profilePaletteOrange = 'profile.paletteOrange';
  static const String profileCloseSheet = 'profile.closeSheet';

  /// Prefix of the category name keys (`category.<slug>`).
  static const String categoryPrefix = 'category';
}
