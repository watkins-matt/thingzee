import 'package:hive/hive.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_hive/model/item.hive.dart';

class HiveItemDatabase extends ItemDatabase {
  late Box<HiveItem> box;

  HiveItemDatabase() {
    box = Hive.box<HiveItem>('items');
  }

  @override
  List<Item> all() {
    final all = box.values.toList();
    return all.map((hiveItem) => hiveItem.toItem()).toList();
  }

  @override
  void delete(Item item) {
    box.delete(item.upc);
  }

  @override
  void deleteAll() {
    box.clear();
  }

  @override
  List<Item> filter(Filter filter) {
    final filteredItems = box.values.where((hiveItem) {
      if (hiveItem.consumable && filter.consumable) {
        return true;
      } else if (!hiveItem.consumable && filter.nonConsumable) {
        return true;
      }
      return false;
    }).toList();
    return filteredItems.map((hiveItem) => hiveItem.toItem()).toList();
  }

  @override
  Item? get(String upc) {
    final result = box.get(upc);
    return result?.toItem();
  }

  @override
  List<Item> getAll(List<String> upcs) {
    var items = <Item>[];

    for (final upc in upcs) {
      final item = get(upc);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  @override
  List<Item> getChanges(DateTime since) {
    final changedItems = box.values
        .where((hiveItem) => hiveItem.lastUpdate != null && hiveItem.lastUpdate!.isAfter(since))
        .toList();
    return changedItems.map((hiveItem) => hiveItem.toItem()).toList();
  }

  @override
  Map<String, Item> map() {
    final all = box.values.toList();
    return {for (var hiveItem in all) hiveItem.upc: hiveItem.toItem()};
  }

  @override
  void put(Item item) {
    assert(item.upc.isNotEmpty && item.name.isNotEmpty);
    final hiveItem = HiveItem.from(item);
    box.put(item.upc, hiveItem);
  }

  @override
  List<Item> search(String string) {
    final matchingItems = box.values
        .where((hiveItem) => hiveItem.name.toLowerCase().contains(string.toLowerCase()))
        .toList();
    return matchingItems.map((hiveItem) => hiveItem.toItem()).toList();
  }
}
