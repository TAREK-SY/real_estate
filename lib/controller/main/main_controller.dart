import 'package:get/get.dart';

/// Tabs of the bottom navigation.
enum MainTab { home, explore, profile }

/// What the Explore tab should do when it is opened from Home.
enum ExploreEntry { browse, search, filters }

/// Selected tab of the main shell.
class MainController extends GetxController {
  final Rx<MainTab> tab = MainTab.home.obs;

  /// Set by [openExplore] and cleared by the Explore tab once handled.
  final Rxn<ExploreEntry> exploreEntry = Rxn<ExploreEntry>();

  void select(MainTab value) => tab.value = value;

  void openExplore([ExploreEntry entry = ExploreEntry.browse]) {
    exploreEntry.value = entry;
    select(MainTab.explore);
  }

  /// Returns the pending entry and clears it, so the same entry asked for
  /// twice is handled twice.
  ExploreEntry? takeExploreEntry() {
    final ExploreEntry? entry = exploreEntry.value;
    exploreEntry.value = null;
    return entry;
  }
}
