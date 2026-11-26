import 'package:material_ui/material_ui.dart';

/// Keys for widgets that tests and accessibility tooling target.
abstract final class AppKeys {
  static const Key loadingView = ValueKey<String>('loadingView');
  static const Key stateMessageView = ValueKey<String>('stateMessageView');
  static const Key retryButton = ValueKey<String>('retryButton');
  static const Key notFoundAction = ValueKey<String>('notFoundAction');
  static const Key splashLogo = ValueKey<String>('splashLogo');
  static const Key googleSignIn = ValueKey<String>('googleSignIn');
  static const Key homeSearch = ValueKey<String>('homeSearch');
  static const Key homeFilter = ValueKey<String>('homeFilter');
  static const Key homeNotifications = ValueKey<String>('homeNotifications');
  static const Key featuredSeeAll = ValueKey<String>('featuredSeeAll');
  static const Key recommendationSeeAll = ValueKey<String>(
    'recommendationSeeAll',
  );
  static const Key featuredList = ValueKey<String>('featuredList');
  static const Key homeScroll = ValueKey<String>('homeScroll');
  static const Key bottomNav = ValueKey<String>('bottomNav');

  static const Key exploreBack = ValueKey<String>('exploreBack');
  static const Key exploreNotifications = ValueKey<String>(
    'exploreNotifications',
  );
  static const Key exploreSearchField = ValueKey<String>('exploreSearchField');
  static const Key exploreFilter = ValueKey<String>('exploreFilter');
  static const Key exploreLayoutToggle = ValueKey<String>(
    'exploreLayoutToggle',
  );
  static const Key exploreFound = ValueKey<String>('exploreFound');
  static const Key exploreScroll = ValueKey<String>('exploreScroll');
  static const Key filterSheet = ValueKey<String>('filterSheet');
  static const Key filterClose = ValueKey<String>('filterClose');
  static const Key filterReset = ValueKey<String>('filterReset');
  static const Key filterApply = ValueKey<String>('filterApply');
  static const Key filterPriceSlider = ValueKey<String>('filterPriceSlider');
  static const Key filterWeightSlider = ValueKey<String>('filterWeightSlider');
  static const Key filterRatingStepper = ValueKey<String>('filterRating');
  static const Key filterStockStepper = ValueKey<String>('filterStock');

  static Key navTab(int index) => ValueKey<String>('navTab$index');
  static Key categoryChip(String slug) => ValueKey<String>('chip:$slug');
  static Key favorite(int productId) => ValueKey<String>('favorite:$productId');
  static Key featuredCard(int productId) =>
      ValueKey<String>('featured:$productId');
  static Key gridCard(int productId) => ValueKey<String>('grid:$productId');
  static Key listCard(int productId) => ValueKey<String>('list:$productId');
  static Key filterType(String slug) => ValueKey<String>('type:$slug');
  static Key stepperMinus(Key stepper) => ValueKey<String>('$stepper-');
  static Key stepperPlus(Key stepper) => ValueKey<String>('$stepper+');
}
