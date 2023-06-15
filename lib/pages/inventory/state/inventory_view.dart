import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

final inventoryProvider = StateNotifierProvider<InventoryView, List<Item>>((ref) {
  return InventoryView(App.repo);
});

class InventoryView extends StateNotifier<List<Item>> {
  final Repository r;
  Filter filter = Filter();
  String query = '';
  Map<String, Inventory> inventory = {};

  InventoryView(this.r) : super(<Item>[]) {
    refresh();
  }

  void add(Inventory inventory) {
    r.inv.put(inventory);
    refresh();
  }

  void delete(Inventory inventory) {
    r.inv.delete(inventory);
    refresh();
  }

  Future<void> search(String value) async {
    query = value;

    if (value.isEmpty) {
      await refresh();
      return;
    }

    state = r.items.search(query);
    state.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> refresh() async {
    // Always update the inventory map
    inventory = r.inv.map();

    // We should keep the query loaded unless the user deletes it
    if (query.isNotEmpty) {
      return await search(query);
    }

    Stopwatch stopwatch = Stopwatch()..start();
    state = r.items.filter(filter);
    state.sort((a, b) => a.name.compareTo(b.name));

    stopwatch.stop();
    final elapsed = stopwatch.elapsed.inMilliseconds;
    log('Loaded initial inventory view in ${elapsed / 1000} seconds.');
  }

  Future<void> downloadImages(ItemThumbnailCache cache) async {
    await cache.loadMapping();

    // Iterate through each image, download everything that isn't cached
    for (final item in state) {
      // If the image URL is empty, skip it. If we have an image
      // loaded already we can skip it as well
      if (item.imageUrl.isNotEmpty) {
        await cache.loadImageFromUrl(item.imageUrl, item.upc);
      }
    }

    await cache.saveMapping();
  }
}
