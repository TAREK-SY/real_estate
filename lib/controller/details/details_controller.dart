import 'package:either_dart/either.dart';
import 'package:get/get.dart';

import '../../core/class/route_arguments.dart';
import '../../core/class/status_request.dart';
import '../../data/datasource/remote/booking_remote_data.dart';
import '../../data/datasource/remote/products_remote_data.dart';
import '../../data/model/product.dart';

/// One listing: shows the card's copy at once, then the full record.
class DetailsController extends GetxController {
  DetailsController({this.args});

  /// Stands in for the route arguments when given (tests).
  final ProductArgs? args;

  ProductsRemoteData get _data => Get.find<ProductsRemoteData>();
  BookingRemoteData get _booking => Get.find<BookingRemoteData>();

  /// State of the full-record request.
  final Rx<StatusRequest> status = StatusRequest.none.obs;

  /// What is shown: the preview until the full record arrives.
  final Rxn<Product> product = Rxn<Product>();

  /// Photo shown in the header pager.
  final RxInt photoIndex = 0.obs;

  final RxBool isBooking = false.obs;

  int? _id;

  @override
  void onInit() {
    super.onInit();
    final ProductArgs? parsed = args ?? ProductArgs.tryParse(Get.arguments);
    if (parsed == null) {
      status.value = StatusRequest.notFoundFailure;
      return;
    }
    _id = parsed.id;
    product.value = parsed.preview;
    load();
  }

  Future<void> load() async {
    final int? id = _id;
    if (id == null) return;
    status.value = StatusRequest.loading;
    final Either<StatusRequest, Product> result = await _data.fetchProduct(id);
    if (isClosed) return;
    result.fold((StatusRequest failure) => status.value = failure, (
      Product full,
    ) {
      product.value = full;
      if (photoIndex.value >= photosOf(full).length) photoIndex.value = 0;
      status.value = StatusRequest.success;
    });
  }

  void showPhoto(int index) => photoIndex.value = index;

  /// Sends the (simulated) booking. Returns [StatusRequest.success] or the
  /// failure, or [StatusRequest.none] when a request is already running.
  Future<StatusRequest> book() async {
    final int? id = _id;
    if (id == null || isBooking.value) return StatusRequest.none;
    isBooking.value = true;
    final Either<StatusRequest, int> result;
    try {
      result = await _booking.book(id);
    } finally {
      if (!isClosed) isBooking.value = false;
    }
    return result.fold(
      (StatusRequest failure) => failure,
      (_) => StatusRequest.success,
    );
  }

  /// Header photos: the gallery, else the card image, else one empty slot
  /// that shows the placeholder.
  static List<String?> photosOf(Product product) {
    if (product.images.isNotEmpty) return product.images;
    return <String?>[product.coverImage];
  }
}
