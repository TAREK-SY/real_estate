import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import '../../controller/favorites/favorites_controller.dart';
import '../../core/constant/app_image_asset.dart';
import '../../core/constant/app_keys.dart';
import '../../core/localization/app_strings.dart';
import '../../core/shared/app_asset_image.dart';
import '../../core/theme/app_palette.dart';
import 'tap_area.dart';

/// Heart that adds or removes a listing from the local favorites. A saved
/// listing shows the heart in the primary color.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.productId,
    required this.title,
    required this.color,
    this.iconSize = 20,
  });

  final int productId;

  /// Listing title, so each heart is told apart by a screen reader.
  final String title;

  /// Color when not a favorite.
  final Color color;
  final double iconSize;

  Future<void> _toggle(
    BuildContext context,
    FavoritesController favorites,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (await favorites.toggle(productId)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.t(AppStrings.favoriteSaveFailed))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final FavoritesController favorites = Get.find<FavoritesController>();
    final AppPalette palette = context.palette;
    return Obx(() {
      final bool saved = favorites.isFavorite(productId);
      return TapArea(
        key: AppKeys.favorite(productId),
        label: AppStrings.tArgs(
          saved ? AppStrings.favoriteRemove : AppStrings.favoriteAdd,
          <String>[title],
        ),
        selected: saved,
        onTap: () => _toggle(context, favorites),
        child: AppAssetImage(
          AppIcon.heart,
          width: iconSize.r,
          height: iconSize.r,
          color: saved ? palette.primary : color,
        ),
      );
    });
  }
}
