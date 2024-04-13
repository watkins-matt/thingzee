import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

final inventoryProvider = StateNotifierProvider<InventoryView, List<JoinedItem>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final sl = ref.watch(shoppingListProvider.notifier);

  return InventoryView(repo, sl);
});

class InventoryView extends StateNotifier<List<JoinedItem>> {
  final Repository r;
  final ShoppingList sl;
  final JoinedItemDatabase joinedItemDb;
  Filter _filter = const Filter();
  String query = '';

  InventoryView(this.r, this.sl)
      : joinedItemDb = JoinedItemDatabase(r.items, r.inv),
        super(<JoinedItem>[]) {
    refresh();
  }

  Filter get filter => _filter;
  set filter(Filter value) {
    _filter = value;
    refresh();
  }

  void addInventory(Inventory inv) {
    joinedItemDb.inventoryDatabase.put(inv);
    refresh();
  }

  void deleteInventory(Inventory inv) {
    joinedItemDb.inventoryDatabase.delete(inv);
    refresh();
    sl.refreshAll();
  }

  Future<void> downloadImages(ItemThumbnailCache cache) async {
    // Iterate through each image, download everything that isn't cached
    for (final joinedItem in state) {
      // If the image URL is empty, skip it. If we have an image
      // loaded already we can skip it as well
      if (joinedItem.item.imageUrl.isNotEmpty) {
        await cache.loadImageFromUrl(joinedItem.item.imageUrl, joinedItem.item.upc);
      }
    }
  }

  Future<void> fuzzySearch(String value) async {
    query = value;

    if (value.isEmpty) {
      await refresh();
      return;
    }

    state = joinedItemDb.fuzzySearch(query);
  }

  Future<void> refresh() async {
    // We should keep the query loaded unless the user deletes it
    if (query.isNotEmpty) {
      return await search(query);
    }

    Stopwatch stopwatch = Log.timerStart();
    state = joinedItemDb.filter(filter);
    Log.timerEnd(stopwatch, 'Loaded inventory view in \$seconds seconds.');
  }

  Future<void> search(String value) async {
    query = value;

    if (value.isEmpty) {
      await refresh();
      return;
    }

    state = joinedItemDb.search(query);
  }
}
