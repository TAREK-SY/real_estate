import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/main/main_controller.dart';
import '../../../core/theme/app_palette.dart';
import '../../widget/app_bottom_nav.dart';
import 'explore_view.dart';
import 'home_view.dart';
import 'profile_view.dart';

/// The signed-in shell: three tabs over a bottom navigation bar. Tabs keep
/// their state (scroll position, loaded pages) while hidden.
class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final MainTab tab = controller.tab.value;
      // The system back button goes to Home first, like the in-app back
      // arrow, and only closes the app from there.
      return PopScope<Object?>(
        canPop: tab == MainTab.home,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (didPop) return;
          FocusManager.instance.primaryFocus?.unfocus();
          controller.select(MainTab.home);
        },
        child: _shell(context, tab),
      );
    });
  }

  Widget _shell(BuildContext context, MainTab tab) {
    return Scaffold(
      backgroundColor: context.palette.white,
      body: IndexedStack(
        index: tab.index,
        children: const <Widget>[HomeView(), ExploreView(), ProfileView()],
      ),
      bottomNavigationBar: AppBottomNav(
        current: tab,
        onTap: (MainTab value) {
          // A field focused on a hidden tab would keep the keyboard up.
          FocusManager.instance.primaryFocus?.unfocus();
          controller.select(value);
        },
      ),
    );
  }
}
