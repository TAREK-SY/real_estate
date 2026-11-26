import 'package:either_dart/either.dart';
import 'package:get/get.dart';

import '../../core/class/status_request.dart';
import '../../data/datasource/remote/products_remote_data.dart';
import '../../data/model/category.dart';
import '../../data/model/product.dart';
import '../../data/model/product_page.dart';
import '../../data/model/product_query.dart';

/// Home tab: featured listings, category chips and the paged
/// recommendation grid.
class HomeController extends GetxController {
  static const int featuredCount = 5;
  static const int pageSize = ProductQuery.defaultLimit;

  ProductsRemoteData get _data => Get.find<ProductsRemoteData>();

  final Rx<StatusRequest> featuredStatus = StatusRequest.none.obs;
  final RxList<Product> featured = <Product>[].obs;

  final RxList<Category> categories = <Category>[].obs;

  /// `null` means all categories.
  final RxnString selectedCategory = RxnString();

  final Rx<StatusRequest> status = StatusRequest.none.obs;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;

  /// Why the last next-page load failed; `null` when it did not.
  final Rxn<StatusRequest> loadMoreError = Rxn<StatusRequest>();

  ProductQuery _query = const ProductQuery();

  // Bumped on every new grid query; a response for an older one is dropped,
  // so switching chips quickly never shows the previous category.
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    loadFeatured();
    loadCategories();
    loadRecommendations();
  }

  Future<void> loadFeatured() async {
    featuredStatus.value = StatusRequest.loading;
    final Either<StatusRequest, ProductPage> result = await _data.fetchProducts(
      const ProductQuery(sort: ProductSort.ratingDesc, limit: featuredCount),
    );
    if (isClosed) return;
    result.fold((StatusRequest failure) => featuredStatus.value = failure, (
      ProductPage page,
    ) {
      featured.assignAll(page.products);
      featuredStatus.value = page.products.isEmpty
          ? StatusRequest.empty
          : StatusRequest.success;
    });
  }

  /// Chips are optional: when categories fail to load, only "All" shows and
  /// the grid still works.
  Future<void> loadCategories() async {
    final Either<StatusRequest, List<Category>> result = await _data
        .fetchCategories();
    if (isClosed) return;
    if (result.isRight) categories.assignAll(result.right);
  }

  void selectCategory(String? slug) {
    if (selectedCategory.value == slug) return;
    selectedCategory.value = slug;
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    final int generation = ++_generation;
    _query = ProductQuery(categorySlug: selectedCategory.value);
    status.value = StatusRequest.loading;
    isLoadingMore.value = false;
    loadMoreError.value = null;
    hasMore.value = false;
    products.clear();

    final Either<StatusRequest, ProductPage> result = await _data.fetchProducts(
      _query,
    );
    if (isClosed || generation != _generation) return;
    result.fold((StatusRequest failure) => status.value = failure, (
      ProductPage page,
    ) {
      products.assignAll(page.products);
      hasMore.value = page.hasMore;
      status.value = page.products.isEmpty
          ? StatusRequest.empty
          : StatusRequest.success;
    });
  }

  /// Next page of the grid, asked for by scrolling. A failure keeps what is
  /// shown and stops further scroll-driven attempts until [retryMore].
  Future<void> loadMore() async {
    if (status.value != StatusRequest.success ||
        isLoadingMore.value ||
        loadMoreError.value != null ||
        !hasMore.value) {
      return;
    }
    final int generation = _generation;
    final ProductQuery next = _query.nextPage();
    isLoadingMore.value = true;
    final Either<StatusRequest, ProductPage> result = await _data.fetchProducts(
      next,
    );
    if (isClosed || generation != _generation) return;
    isLoadingMore.value = false;
    if (result.isLeft) {
      loadMoreError.value = result.left;
      return;
    }
    _query = next;
    products.addAll(result.right.products);
    hasMore.value = result.right.hasMore;
  }

  Future<void> retryMore() {
    loadMoreError.value = null;
    return loadMore();
  }

  /// Pull to refresh. Loaded sections would come back unchanged from the
  /// request cache, so only the ones that failed are asked again; the rest
  /// stay on screen instead of flashing back to a spinner.
  Future<void> refreshAll() async {
    await Future.wait(<Future<void>>[
      if (featuredStatus.value != StatusRequest.success) loadFeatured(),
      if (categories.isEmpty) loadCategories(),
      if (status.value != StatusRequest.success) loadRecommendations(),
    ]);
  }
}
