import 'package:easy_localization/easy_localization.dart' as ez;

import '../../data/model/category.dart';
import '../../data/model/product.dart';
import 'app_strings.dart';

/// Display name of a category in the current language.
///
/// Known slugs have a translation; a slug the API adds later falls back to
/// the name the API sends, so a new category still shows up with a label.
String categoryDisplayName(Category category) {
  final String key = '${AppStrings.categoryPrefix}.${category.slug}';
  return ez.trExists(key) ? ez.tr(key) : category.name;
}

/// The location line of a listing card. DummyJSON has no address, so the
/// brand stands in for it, or the category name when there is no brand.
String listingSubtitle(Product product) =>
    product.brand ??
    categoryDisplayName(
      Category(slug: product.category, name: product.category),
    );
