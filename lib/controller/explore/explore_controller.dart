import 'dart:async';

import 'package:either_dart/either.dart';
import 'package:get/get.dart';

import '../../core/class/status_request.dart';
import '../../data/datasource/remote/products_remote_data.dart';
import '../../data/model/category.dart';
import '../../data/model/filter_bounds.dart';
import '../../data/model/product_filter.dart';
import '../../data/model/product_page.dart';
import '../../data/model/product_query.dart';
import '../shared/product_pager.dart';

enum ExploreLayout { list, grid }

/// Explore tab: text search, category chips, the filter sheet and the
/// results as a list or a grid.
///
/// A text search alone or a single category alone is paged by the API.
/// Anything else is beyond what DummyJSON can filter, so the whole matching
/// set is fetched once (cached) and narrowed on the device.
class ExploreController extends GetxController {
  static const Duration searchDebounce = Duration(milliseconds: 400);

  ProductsRemoteData get _data => Get.find<ProductsRemoteData>();

  late final ProductPager results = ProductPager(
    fetch: (ProductQuery query) => _data.fetchProducts(query),
    isClosed: () => isClosed,
  );

  final RxList<Category> categories = <Category>[].obs;

  /// The search the results are for (trimmed); typing updates it after a
  /// pause.
  final RxString search = ''.obs;
  final Rx<ProductFilter> filter = ProductFilter.none.obs;
  final Rx<ExploreLayout> layout = ExploreLayout.list.obs;

  /// The filter sheet's working copy; only [applyDraft] makes it current.
  final Rx<ProductFilter> draft = ProductFilter.none.obs;

  /// Price and weight spans of the current search, for the sheet sliders.
  final Rxn<FilterBounds> bounds = Rxn<FilterBounds>();
  final Rx<StatusRequest> boundsStatus = StatusRequest.none.obs;
  String? _boundsSearch;
  int _boundsGeneration = 0;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// Chips are optional: when categories fail to load, only "All" shows
  /// until [retry].
  Future<void> loadCategories() async {
    final Either<StatusRequest, List<Category>> result = await _data
        .fetchCategories();
    if (isClosed) return;
    if (result.isRight) categories.assignAll(result.right);
  }

  /// Retry after a failed load; the chips are asked for again if they never
  /// came.
  Future<void> retry() {
    if (categories.isEmpty) loadCategories();
    return results.reload();
  }

  Future<void> load() {
    final ProductFilter current = filter.value;
    final String text = search.value;
    final String? single = current.categories.length == 1
        ? current.categories.single
        : null;
    if (current.needsLocalFiltering(searching: text.isNotEmpty)) {
      return results.load(
        ProductQuery.all(
          search: text,
          categorySlug: text.isEmpty ? single : null,
        ),
        refine: current.apply,
      );
    }
    return results.load(ProductQuery(search: text, categorySlug: single));
  }

  /// Typing: searches once the text has rested for [searchDebounce].
  void onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () => submitSearch(text));
  }

  /// Search now (keyboard action); a pending debounced search is dropped.
  void submitSearch(String text) {
    _debounce?.cancel();
    final String trimmed = text.trim();
    if (trimmed == search.value) return;
    search.value = trimmed;
    load();
  }

  /// A chip picks one category; "All" (`null`) clears the categories.
  void selectCategory(String? slug) {
    final Set<String> next = slug == null ? <String>{} : <String>{slug};
    _setFilter(filter.value.withCategories(next));
  }

  void toggleLayout() => layout.value = layout.value == ExploreLayout.list
      ? ExploreLayout.grid
      : ExploreLayout.list;

  // Filter sheet

  /// Starts editing from the current filter and loads the slider spans.
  void openFilters() {
    draft.value = filter.value;
    loadBounds();
  }

  /// Spans come from every item of the current search, before any filter,
  /// so they do not shrink as filters are added.
  Future<void> loadBounds() async {
    final String text = search.value;
    if (_boundsSearch == text && boundsStatus.value == StatusRequest.success) {
      _fitDraft(bounds.value!);
      return;
    }
    if (_boundsSearch != text) {
      bounds.value = null;
      _boundsSearch = null;
    }
    final int current = ++_boundsGeneration;
    boundsStatus.value = StatusRequest.loading;
    final Either<StatusRequest, ProductPage> result = await _data.fetchProducts(
      ProductQuery.all(search: text),
    );
    if (isClosed || current != _boundsGeneration) return;
    result.fold((StatusRequest failure) => boundsStatus.value = failure, (
      ProductPage page,
    ) {
      final FilterBounds span = FilterBounds.from(page.products);
      bounds.value = span;
      _boundsSearch = text;
      _fitDraft(span);
      boundsStatus.value = StatusRequest.success;
    });
  }

  // A range kept from an earlier search can reach past these spans or miss
  // them entirely; the sliders can only show what lies inside.
  void _fitDraft(FilterBounds span) {
    final ProductFilter d = draft.value;
    final ValueRange? price = span.price;
    final ValueRange? weight = span.weight;
    draft.value = d
        .withPrice(price == null ? d.price : d.price?.within(price))
        .withWeight(weight == null ? d.weight : d.weight?.within(weight));
  }

  void toggleDraftCategory(String slug) =>
      draft.value = draft.value.toggleCategory(slug);

  /// Slider positions (0..1 on the log price scale); the full span is no
  /// price filter at all.
  void setDraftPrice(double start, double end) {
    final FilterBounds? span = bounds.value;
    if (span == null) return;
    draft.value = draft.value.withPrice(
      start <= 0 && end >= 1
          ? null
          : ValueRange(span.priceAt(start), span.priceAt(end)),
    );
  }

  void setDraftWeight(double start, double end) {
    final ValueRange? span = bounds.value?.weight;
    if (span == null) return;
    draft.value = draft.value.withWeight(
      start <= span.start && end >= span.end ? null : ValueRange(start, end),
    );
  }

  void setDraftMinRating(int value) =>
      draft.value = draft.value.withMinRating(value);

  void setDraftMinStock(int value) =>
      draft.value = draft.value.withMinStock(value);

  void resetDraft() => draft.value = ProductFilter.none;

  void applyDraft() => _setFilter(draft.value);

  void _setFilter(ProductFilter next) {
    if (next == filter.value) return;
    filter.value = next;
    load();
  }
}
