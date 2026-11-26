import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../../controller/main/main_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widget/app_bottom_nav.dart';
import 'home_view.dart';

/// The signed-in shell: three tabs over a bottom navigation bar. Tabs keep
/// their state (scroll position, loaded pages) while hidden.
class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final MainTab tab = controller.tab.value;
      return Scaffold(
        backgroundColor: context.palette.white,
        body: IndexedStack(
          index: tab.index,
          children: const <Widget>[
            HomeView(),
            _PendingTab(titleKey: AppStrings.navExplore),
            _PendingTab(titleKey: AppStrings.navProfile),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          current: tab,
          onTap: controller.select,
        ),
      );
    });
  }
}

// Explore and Profile get their screens in the next builds; until then the
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
