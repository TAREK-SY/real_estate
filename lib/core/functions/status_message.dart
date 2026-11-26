import '../class/status_request.dart';
import '../localization/app_strings.dart';

/// The translation key of the user-facing message for a request state.
///
/// Users never see a raw exception or status code; every failure maps to a
/// short sentence they can act on.
String statusMessageKey(StatusRequest status) => switch (status) {
  StatusRequest.loading => AppStrings.stateLoading,
  StatusRequest.empty => AppStrings.stateEmpty,
  StatusRequest.offlineFailure => AppStrings.stateOffline,
  StatusRequest.timeoutFailure => AppStrings.stateTimeout,
  StatusRequest.serverFailure => AppStrings.stateServer,
  StatusRequest.notFoundFailure => AppStrings.stateNotFound,
  StatusRequest.unexpectedResponse => AppStrings.stateUnexpected,
  StatusRequest.failure ||
  StatusRequest.none ||
  StatusRequest.success => AppStrings.stateFailure,
};

/// Whether retrying can help. A 404 will not change on a retry.
bool canRetry(StatusRequest status) =>
    status.isFailure && status != StatusRequest.notFoundFailure;
