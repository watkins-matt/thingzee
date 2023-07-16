import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

final inventoryProvider = StateNotifierProvider<InventoryView, List<JoinedItem>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return InventoryView(repo);
});

class InventoryView extends StateNotifier<List<JoinedItem>> {
  final Repository r;
  final JoinedItemDatabase joinedItemDb;
  Filter filter = Filter();
  String query = '';

  InventoryView(this.r)
      : joinedItemDb = JoinedItemDatabase(r.items, r.inv),
        super(<JoinedItem>[]) {
    refresh();
  }

  void addInventory(Inventory inv) {
    joinedItemDb.inventoryDatabase.put(inv);
    refresh();
  }

  void deleteInventory(Inventory inv) {
    joinedItemDb.inventoryDatabase.delete(inv);
    refresh();
  }

  Future<void> downloadImages(ItemThumbnailCache cache) async {
    await cache.loadMapping();

    // Iterate through each image, download everything that isn't cached
    for (final joinedItem in state) {
      // If the image URL is empty, skip it. If we have an image
      // loaded already we can skip it as well
      if (joinedItem.item.imageUrl.isNotEmpty) {
        await cache.loadImageFromUrl(joinedItem.item.imageUrl, joinedItem.item.upc);
      }
    }

    await cache.saveMapping();
  }

  Future<void> refresh() async {
    // We should keep the query loaded unless the user deletes it
    if (query.isNotEmpty) {
      return await search(query);
    }

    Stopwatch stopwatch = Log.timerStart();
    state = joinedItemDb.filter(filter);
    Log.timerEnd(stopwatch, 'Loaded initial inventory view in \$seconds seconds.');
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
