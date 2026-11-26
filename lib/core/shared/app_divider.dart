import 'package:material_ui/material_ui.dart';

import '../theme/app_palette.dart';

/// The design's 1 px divider in primary at 10%.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.palette.primarySoft);
}
