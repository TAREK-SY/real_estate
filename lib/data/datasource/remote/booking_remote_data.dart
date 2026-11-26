import 'package:either_dart/either.dart';

import '../../../core/class/crud.dart';
import '../../../core/class/status_request.dart';
import '../../../core/functions/json_parsers.dart';
import '../../../link_api.dart';

/// Booking requests. DummyJSON has no bookings, so a booking is sent as a
/// one-item cart; the API simulates the write and keeps nothing.
class BookingRemoteData {
  BookingRemoteData(this._crud);

  /// The API has no accounts; its sample user stands in for the guest.
  static const int demoUserId = 1;

  final Crud _crud;

  /// Returns the id the server gave the (unsaved) request.
  Future<Either<StatusRequest, int>> book(int productId) async {
    final Either<StatusRequest, ApiResult> result = await _crud.postJson(
      AppLink.cartsAdd,
      <String, dynamic>{
        'userId': demoUserId,
        'products': <Map<String, int>>[
          <String, int>{'id': productId, 'quantity': 1},
        ],
      },
    );
    if (result.isLeft) return Left(result.left);
    final int? id = jsonInt(result.right.map?['id']);
    return id == null
        ? const Left(StatusRequest.unexpectedResponse)
        : Right(id);
  }
}
