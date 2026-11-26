import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/class/handling_data_view.dart';
import '../../core/class/status_request.dart';
import '../../core/functions/status_message.dart';
import '../../core/localization/app_strings.dart';
import '../../data/model/product.dart';
import 'property_grid_card.dart';
import 'property_list_card.dart';

enum ResultsLayout { list, grid }

/// A paged product list as a sliver: a state view until the first page is
/// in, then the cards, with a spinner or a retry row while the next page
/// loads or after it failed.
class ProductResultsSliver extends StatelessWidget {
  const ProductResultsSliver({
    super.key,
    required this.layout,
    required this.status,
    required this.products,
    required this.onRetry,
    required this.onRetryMore,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.emptyMessageKey = AppStrings.stateEmpty,
  });

  final ResultsLayout layout;
  final StatusRequest status;
  final List<Product> products;
  final VoidCallback onRetry;
  final VoidCallback onRetryMore;
  final bool isLoadingMore;
  final StatusRequest? loadMoreError;
  final String emptyMessageKey;

  @override
  Widget build(BuildContext context) {
    if (status != StatusRequest.success) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 240.h,
          child: HandlingDataView(
            status: status,
            onRetry: onRetry,
            emptyMessageKey: emptyMessageKey,
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }
    final bool grid = layout == ResultsLayout.grid;
    final int rows = grid ? (products.length + 1) ~/ 2 : products.length;
    final bool footer = isLoadingMore || loadMoreError != null;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverList.builder(
        itemCount: rows + (footer ? 1 : 0),
        itemBuilder: (_, int row) {
          if (row == rows) return _footer();
          return Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : (grid ? 20 : 16).h),
            child: grid
                ? _gridRow(row)
                : PropertyListCard(product: products[row]),
          );
        },
      ),
    );
  }

  /// Two cards side by side; the row is as tall as its taller card instead
  /// of a fixed aspect ratio.
  Widget _gridRow(int row) {
    final Product start = products[row * 2];
    final Product? end = row * 2 + 1 < products.length
        ? products[row * 2 + 1]
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: PropertyGridCard(product: start)),
        SizedBox(width: 16.w),
        Expanded(
          child: end == null
              ? const SizedBox.shrink()
              : PropertyGridCard(product: end),
        ),
      ],
    );
  }

  Widget _footer() {
    final StatusRequest? error = loadMoreError;
    if (error != null) {
      return StateMessageView(
        messageKey: statusMessageKey(error),
        onRetry: canRetry(error) ? onRetryMore : null,
      );
    }
    return SizedBox(height: 64.h, child: const LoadingView());
  }
}
