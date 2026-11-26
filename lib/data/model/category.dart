import '../../core/functions/json_parsers.dart';

/// A product category from `GET /products/categories`.
class Category {
  const Category({required this.slug, required this.name});

  /// Returns `null` when the slug is missing: a category without a slug
  /// cannot be queried, so it is not shown.
  static Category? tryParse(Object? raw) {
    // Older API versions returned bare strings instead of objects.
    if (raw is String) {
      final String slug = raw.trim();
      return slug.isEmpty ? null : Category(slug: slug, name: slug);
    }
    final Map<String, dynamic>? json = jsonMap(raw);
    if (json == null) return null;
    final String slug = jsonString(json['slug'])?.trim() ?? '';
    if (slug.isEmpty) return null;
    final String name = jsonString(json['name'])?.trim() ?? '';
    return Category(slug: slug, name: name.isEmpty ? slug : name);
  }

  static List<Category> listFrom(Object? raw) {
    if (raw is! List) return const <Category>[];
    return List<Category>.unmodifiable(raw.map(tryParse).whereType<Category>());
  }

  final String slug;
  final String name;

  @override
  bool operator ==(Object other) => other is Category && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;
}
