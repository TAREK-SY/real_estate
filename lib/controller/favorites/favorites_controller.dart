import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/services.dart';

/// Favorite listings, kept on the device only.
class FavoritesController extends GetxController {
  static const String storageKey = 'favorites.ids';

  final RxSet<int> ids = <int>{}.obs;

  SharedPreferences get _prefs => Get.find<MyServices>().sharedPreferences;

  // The set as last confirmed by the device storage, and the number of the
  // newest write, so an older write finishing late cannot undo a newer tap.
  Set<int> _stored = <int>{};
  int _storedWrite = 0;
  int _writes = 0;

  @override
  void onInit() {
    super.onInit();
    final List<String> saved = _prefs.getStringList(storageKey) ?? <String>[];
    ids.addAll(saved.map(int.tryParse).whereType<int>());
    _stored = Set<int>.of(ids);
  }

  bool isFavorite(int id) => ids.contains(id);

  /// Toggles [id] and saves the whole set. Returns false when the newest
  /// write is refused; the set then goes back to the last stored one. A
  /// write overtaken by a newer tap returns true: the newer one reports.
  Future<bool> toggle(int id) async {
    if (!ids.remove(id)) ids.add(id);
    final int write = ++_writes;
    final Set<int> snapshot = Set<int>.of(ids);
    bool saved;
    try {
      saved = await _prefs.setStringList(
        storageKey,
        snapshot.map((int id) => '$id').toList(growable: false),
      );
    } on Exception {
      saved = false;
    }
    if (saved && write > _storedWrite) {
      _stored = snapshot;
      _storedWrite = write;
    }
    if (write != _writes) return true;
    if (!saved) {
      ids
        ..clear()
        ..addAll(_stored);
    }
    return saved;
  }
}
