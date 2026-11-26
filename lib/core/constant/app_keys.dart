import 'package:material_ui/material_ui.dart';

/// Keys for widgets that tests and accessibility tooling target.
abstract final class AppKeys {
  static const Key loadingView = ValueKey<String>('loadingView');
  static const Key stateMessageView = ValueKey<String>('stateMessageView');
  static const Key retryButton = ValueKey<String>('retryButton');
  static const Key notFoundAction = ValueKey<String>('notFoundAction');
  static const Key splashLogo = ValueKey<String>('splashLogo');
}
