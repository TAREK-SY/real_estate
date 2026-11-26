/// State of a request, as seen by controllers and views.
enum StatusRequest {
  none,
  loading,
  success,

  /// The request succeeded but returned nothing to show.
  empty,

  /// No network connection (checked before sending, or a socket error).
  offlineFailure,

  /// The server did not answer within the timeout.
  timeoutFailure,

  /// 5xx, or a transport error after the connection was established.
  serverFailure,

  /// 404: the resource does not exist.
  notFoundFailure,

  /// 2xx with a body that is not the JSON shape we expect.
  unexpectedResponse,

  /// Any other 4xx.
  failure;

  bool get isFailure => switch (this) {
    offlineFailure ||
    timeoutFailure ||
    serverFailure ||
    notFoundFailure ||
    unexpectedResponse ||
    failure => true,
    _ => false,
  };
}
