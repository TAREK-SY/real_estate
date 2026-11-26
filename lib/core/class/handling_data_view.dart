import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../constant/app_keys.dart';
import '../functions/status_message.dart';
import '../localization/app_strings.dart';
import '../shared/primary_button.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'status_request.dart';

/// Shows [child] on success and a state view otherwise: a spinner while
/// loading, a message when empty, and a message with a retry button on
/// failures that a retry can fix.
class HandlingDataView extends StatelessWidget {
  const HandlingDataView({
    super.key,
    required this.status,
    required this.child,
    this.onRetry,
    this.emptyMessageKey = AppStrings.stateEmpty,
  });

  final StatusRequest status;
  final Widget child;
  final VoidCallback? onRetry;
  final String emptyMessageKey;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      StatusRequest.loading => const LoadingView(),
      StatusRequest.empty => StateMessageView(messageKey: emptyMessageKey),
      StatusRequest.none || StatusRequest.success => child,
      _ => StateMessageView(
        messageKey: statusMessageKey(status),
        onRetry: canRetry(status) ? onRetry : null,
      ),
    };
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: AppKeys.loadingView,
      child: Semantics(
        label: AppStrings.t(AppStrings.stateLoading),
        child: SizedBox.square(
          dimension: 32.r,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: context.palette.primary,
          ),
        ),
      ),
    );
  }
}

/// A centered, translated message with an optional retry button.
class StateMessageView extends StatelessWidget {
  const StateMessageView({super.key, required this.messageKey, this.onRetry});

  final String messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Center(
      key: AppKeys.stateMessageView,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppStrings.t(messageKey),
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 16,
                height: 1.5,
                color: palette.black2,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              SizedBox(height: 20.h),
              PrimaryButton(
                key: AppKeys.retryButton,
                label: AppStrings.t(AppStrings.stateRetry),
                onPressed: onRetry,
                verticalPadding: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
