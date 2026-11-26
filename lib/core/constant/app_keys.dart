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

  static Key navTab(int index) => ValueKey<String>('navTab$index');
  static Key categoryChip(String slug) => ValueKey<String>('chip:$slug');
  static Key favorite(int productId) => ValueKey<String>('favorite:$productId');
  static Key featuredCard(int productId) =>
      ValueKey<String>('featured:$productId');
  static Key gridCard(int productId) => ValueKey<String>('grid:$productId');
}
