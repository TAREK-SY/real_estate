/// Typed navigation data. Each type parses the raw `Get.arguments` with
/// `tryParse`, which returns `null` instead of throwing, so a screen opened
/// without valid data can show a message rather than fail.
library;

import '../../data/model/product.dart';

/// The listing to show on the details screen.
class ProductArgs {
  const ProductArgs({required this.id, this.preview});

  final int id;

  /// The card's copy of the listing, shown while the full record loads.
  /// Cards in some result modes carry only a few fields.
  final Product? preview;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'preview': preview,
  };

  static ProductArgs? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    if (id is! int || id <= 0) return null;
    final Object? preview = raw['preview'];
    return ProductArgs(
      id: id,
      preview: preview is Product && preview.id == id ? preview : null,
    );
  }
}
