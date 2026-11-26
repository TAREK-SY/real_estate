import 'package:either_dart/either.dart';
import 'package:get/get.dart';

import '../../core/class/status_request.dart';
import '../../data/model/product.dart';
import '../../data/model/product_page.dart';
import '../../data/model/product_query.dart';

typedef ProductFetcher = Future<Either<StatusRequest, ProductPage>> Function(
  ProductQuery query,
);

/// Narrows a fetched page on the device. A pager given one shows the whole
/// narrowed set at once: there are no further pages to ask the API for.
typedef ProductRefiner = List<Product> Function(List<Product> products);

/// A product list loaded page by page: the Home grid and the Explore results.
///
/// Each [load] starts a new generation; a response for an older one is
/// dropped, so a quick change of query never shows the previous results.
class ProductPager {
  ProductPager({required this._fetch, required this._isClosed});

  final ProductFetcher _fetch;
  final bool Function() _isClosed;

  final Rx<StatusRequest> status = StatusRequest.none.obs;
  final RxList<Product> products = <Product>[].obs;

  /// How many items match: the API total, or the narrowed count.
  final RxInt total = 0.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;

  /// Why the last next-page load failed; `null` when it did not.
  final Rxn<StatusRequest> loadMoreError = Rxn<StatusRequest>();

  /// Bumped on every [load]; views watch it to scroll back to the top.
  final RxInt generation = 0.obs;

  ProductQuery? _query;
  ProductRefiner? _refine;

  Future<void> load(ProductQuery query, {ProductRefiner? refine}) async {
    final int current = ++generation.value;
    _query = query;
    _refine = refine;
    status.value = StatusRequest.loading;
    isLoadingMore.value = false;
    loadMoreError.value = null;
    hasMore.value = false;
    total.value = 0;
    products.clear();

    final Either<StatusRequest, ProductPage> result = await _fetch(query);
    if (_isClosed() || current != generation.value) return;
    result.fold((StatusRequest failure) => status.value = failure, (
      ProductPage page,
    ) {
      final List<Product> items = refine == null
          ? page.products
          : refine(page.products);
      products.assignAll(items);
      total.value = refine == null ? page.total : items.length;
      hasMore.value = refine == null && page.hasMore;
      status.value = items.isEmpty
          ? StatusRequest.empty
          : StatusRequest.success;
    });
  }

  /// Loads the current query again, for a retry after a failure.
  Future<void> reload() {
    final ProductQuery? query = _query;
    return query == null ? Future<void>.value() : load(query, refine: _refine);
  }

  /// Next page, asked for by scrolling. A failure keeps what is shown and
  /// stops further scroll-driven attempts until [retryMore].
  Future<void> loadMore() async {
    final ProductQuery? query = _query;
    if (query == null ||
        status.value != StatusRequest.success ||
        isLoadingMore.value ||
        loadMoreError.value != null ||
        !hasMore.value) {
      return;
    }
    final int current = generation.value;
    final ProductQuery next = query.nextPage();
    isLoadingMore.value = true;
    final Either<StatusRequest, ProductPage> result = await _fetch(next);
    if (_isClosed() || current != generation.value) return;
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
}
