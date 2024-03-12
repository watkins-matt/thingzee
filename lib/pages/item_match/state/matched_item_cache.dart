import 'package:hooks_riverpod/hooks_riverpod.dart';

final matchedItemCacheProvider = StateNotifierProvider<MatchedItemCache, Map<String, String>>(
  (ref) => MatchedItemCache({}),
);

class MatchedItemCache extends StateNotifier<Map<String, String>> {
  MatchedItemCache(super.state);

  void clear() {
    state = {};
  }

  void copyFrom(Map<String, String> cache) {
    state = Map<String, String>.from(cache);
  }

  void delete(String barcode) {
    Map<String, String> newItems = Map<String, String>.from(state);
    newItems.remove(barcode);
    state = newItems;
  }

  String? get(String barcode) {
    return state[barcode];
  }

  void put(String barcode, String upc) {
    Map<String, String> newItems = Map<String, String>.from(state);
    newItems[barcode] = upc;
    state = newItems;
  }
}
