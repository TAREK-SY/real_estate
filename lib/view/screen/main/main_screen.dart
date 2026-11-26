import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/main/main_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widget/app_bottom_nav.dart';
import 'explore_view.dart';
import 'home_view.dart';

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
        children: const <Widget>[
          HomeView(),
          ExploreView(),
          _PendingTab(titleKey: AppStrings.navProfile),
        ],
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

// Profile gets its screen in the next build; until then the
// tab shows its name so navigation can be exercised end to end.
class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.t(titleKey),
        style: appTextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: context.palette.black1,
        ),
      ),
    );
  }
}
