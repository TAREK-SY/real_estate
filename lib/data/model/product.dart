import '../../core/functions/json_parsers.dart';
import 'review.dart';

class ProductDimensions {
  const ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  static ProductDimensions? tryParse(Object? raw) {
    final Map<String, dynamic>? json = jsonMap(raw);
    if (json == null) return null;
    final double? width = jsonDouble(json['width']);
    final double? height = jsonDouble(json['height']);
    final double? depth = jsonDouble(json['depth']);
    if (width == null || height == null || depth == null) return null;
    return ProductDimensions(width: width, height: height, depth: depth);
  }

  final double width;
  final double height;
  final double depth;
}

/// A DummyJSON product, shown as a listing in the app.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.description = '',
    this.category = '',
    this.brand,
    this.rating = 0,
    this.stock,
    this.weight,
    this.dimensions,
    this.thumbnail,
    this.images = const <String>[],
    this.tags = const <String>[],
    this.reviews = const <Review>[],
  });

  /// Returns `null` for an item without an id or title, which the list skips
  /// instead of rendering a broken card.
  static Product? tryParse(Map<String, dynamic> json) {
    final int? id = jsonInt(json['id']);
    final String title = jsonString(json['title'])?.trim() ?? '';
    if (id == null || title.isEmpty) return null;

    final String? brand = jsonString(json['brand'])?.trim();
    final String? thumbnail = jsonString(json['thumbnail'])?.trim();

    return Product(
      id: id,
      title: title,
      price: jsonDouble(json['price']) ?? 0,
      description: jsonString(json['description'])?.trim() ?? '',
      category: jsonString(json['category'])?.trim() ?? '',
      brand: (brand == null || brand.isEmpty) ? null : brand,
      rating: jsonDouble(json['rating']) ?? 0,
      stock: jsonInt(json['stock']),
      weight: jsonDouble(json['weight']),
      dimensions: ProductDimensions.tryParse(json['dimensions']),
      thumbnail: (thumbnail == null || thumbnail.isEmpty) ? null : thumbnail,
      images: jsonStringList(json['images']),
      tags: jsonStringList(json['tags']),
      reviews: jsonList(json['reviews'], Review.fromJson),
    );
  }

  final int id;
  final String title;
  final double price;
  final String description;

  /// Category slug.
  final String category;
  final String? brand;
  final double rating;
  final int? stock;
  final double? weight;
  final ProductDimensions? dimensions;
  final String? thumbnail;
  final List<String> images;
  final List<String> tags;
  final List<Review> reviews;

  /// The image for cards: the thumbnail, else the first gallery image.
  String? get coverImage => thumbnail ?? (images.isEmpty ? null : images.first);
}
