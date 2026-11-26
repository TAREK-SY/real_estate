import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/services.dart';

/// Favorite listings, kept on the device only.
class FavoritesController extends GetxController {
  static const String storageKey = 'favorites.ids';

  final RxSet<int> ids = <int>{}.obs;

  SharedPreferences get _prefs => Get.find<MyServices>().sharedPreferences;

  @override
  void onInit() {
    super.onInit();
    final List<String> saved = _prefs.getStringList(storageKey) ?? <String>[];
    ids.addAll(saved.map(int.tryParse).whereType<int>());
  }

  bool isFavorite(int id) => ids.contains(id);

  Future<void> toggle(int id) async {
    if (!ids.remove(id)) ids.add(id);
    await _prefs.setStringList(
      storageKey,
      ids.map((int id) => '$id').toList(growable: false),
    );
  }
}
