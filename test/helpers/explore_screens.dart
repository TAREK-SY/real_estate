import 'package:get/get.dart';
import 'package:real_estate/bindings/app_bindings.dart';
import 'package:real_estate/controller/explore/explore_controller.dart';
import 'package:real_estate/controller/main/main_controller.dart';

/// The main shell opened on the Explore tab, as a list, a grid, or with the
/// filter sheet open, for the screen matrices.
class ExploreTabBinding extends Bindings {
  ExploreTabBinding({this.grid = false, this.filters = false});

  final bool grid;
  final bool filters;

  @override
  void dependencies() {
    MainBinding().dependencies();
    final MainController main = Get.find<MainController>();
    main.openExplore(filters ? ExploreEntry.filters : ExploreEntry.browse);
    if (grid) Get.find<ExploreController>().toggleLayout();
  }
}

/// Matrix entries: name -> binding, all on `MainScreen`.
final Map<String, Bindings Function()> exploreScreens =
    <String, Bindings Function()>{
      'ExploreList': ExploreTabBinding.new,
      'ExploreGrid': () => ExploreTabBinding(grid: true),
      'FilterSheet': () => ExploreTabBinding(filters: true),
    };
