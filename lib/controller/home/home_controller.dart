import 'package:either_dart/either.dart';
import 'package:get/get.dart';

import '../../core/class/status_request.dart';
import '../../data/datasource/remote/products_remote_data.dart';
import '../../data/model/category.dart';
import '../../data/model/product.dart';
import '../../data/model/product_page.dart';
import '../../data/model/product_query.dart';
import '../shared/product_pager.dart';

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

  late final ProductPager _grid = ProductPager(
    fetch: (ProductQuery query) => _data.fetchProducts(query),
    isClosed: () => isClosed,
  );

  Rx<StatusRequest> get status => _grid.status;
  RxList<Product> get products => _grid.products;
  RxBool get isLoadingMore => _grid.isLoadingMore;
  RxBool get hasMore => _grid.hasMore;

  /// Why the last next-page load failed; `null` when it did not.
  Rxn<StatusRequest> get loadMoreError => _grid.loadMoreError;

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

  Future<void> loadRecommendations() =>
      _grid.load(ProductQuery(categorySlug: selectedCategory.value));

  /// Next page of the grid, asked for by scrolling. A failure keeps what is
  /// shown and stops further scroll-driven attempts until [retryMore].
  Future<void> loadMore() => _grid.loadMore();

  Future<void> retryMore() => _grid.retryMore();

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
