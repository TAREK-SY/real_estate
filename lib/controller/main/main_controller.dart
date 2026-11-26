import 'package:get/get.dart';

/// Tabs of the bottom navigation.
enum MainTab { home, explore, profile }

/// Selected tab of the main shell.
class MainController extends GetxController {
  final Rx<MainTab> tab = MainTab.home.obs;

  void select(MainTab value) => tab.value = value;

  void openExplore() => select(MainTab.explore);
}
