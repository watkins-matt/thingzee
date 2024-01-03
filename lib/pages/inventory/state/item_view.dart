import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

final itemViewProvider = StateNotifierProvider<ItemView, List<Item>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return ItemView(repo);
});

class ItemView extends StateNotifier<List<Item>> {
  final Repository r;
  final ItemDatabase itemDb;
  Filter _filter = const Filter();
  String query = '';

  ItemView(this.r)
      : itemDb = r.items,
        super(<Item>[]) {
    refresh();
  }

  Filter get filter => _filter;
  set filter(Filter value) {
    _filter = value;
    refresh();
  }

  void delete(Item item) {
    itemDb.delete(item);
    refresh();
  }

  Future<void> downloadImages(ItemThumbnailCache cache) async {
    for (final item in state) {
      if (item.imageUrl.isNotEmpty) {
        await cache.loadImageFromUrl(item.imageUrl, item.upc);
      }
    }
  }

  Future<void> fuzzySearch(String value) async {
    query = value;

    if (value.isEmpty) {
      await refresh();
      return;
    }

    state = itemDb.fuzzySearch(query);
  }

  void put(Item item) {
    final existingItem = itemDb.get(item.upc);

    if (existingItem != null) {
      final mergedItem = existingItem.merge(item);
      itemDb.put(mergedItem);
    } else {
      itemDb.put(item);
    }

    refresh();
  }

  Future<void> refresh() async {
    if (query.isNotEmpty) {
      return await search(query);
    }

    Stopwatch stopwatch = Log.timerStart();
    state = itemDb.filter(filter);
    Log.timerEnd(stopwatch, 'Loaded item view in \$seconds seconds.');
  }

  Future<void> search(String value) async {
    query = value;

    if (value.isEmpty) {
      await refresh();
      return;
    }

    state = itemDb.search(query);
  }
}
