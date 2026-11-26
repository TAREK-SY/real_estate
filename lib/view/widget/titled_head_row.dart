import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Head row with a button at each end and a centered title.
class TitledHeadRow extends StatelessWidget {
  const TitledHeadRow({
    super.key,
    required this.title,
    required this.leading,
    required this.trailing,
  });

  final String title;
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        leading,
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: context.palette.black1,
              ),
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}
