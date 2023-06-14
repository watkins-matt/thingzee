import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';

class JoinedItem implements Comparable<JoinedItem> {
  final Item item;
  final Inventory inventory;
  JoinedItem(this.item, this.inventory);

  @override
  int compareTo(JoinedItem other) {
    return item.name.compareTo(other.item.name);
  }
}

class JoinedItemDatabase {
  final ItemDatabase itemDatabase;
  final InventoryDatabase inventoryDatabase;

  JoinedItemDatabase(this.itemDatabase, this.inventoryDatabase);

  List<JoinedItem> all() {
    List<JoinedItem> joinedItems = [];
    Map<String, Inventory> inventoryMap = inventoryDatabase.map();

    for (final key in inventoryMap.keys) {
      final inventory = inventoryMap[key]!;
      final item = itemDatabase.get(key);

      if (item.isPresent) {
        joinedItems.add(JoinedItem(item.value, inventory));
      }
    }

    // Sort everything by name
    joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));

    return joinedItems;
  }

  List<JoinedItem> search(String string) {
    List<Item> results = itemDatabase.search(string);
    List<JoinedItem> joinedItems = [];

    for (final item in results) {
      final inventory = inventoryDatabase.get(item.upc);

      if (inventory.isPresent) {
        joinedItems.add(JoinedItem(item, inventory.value));
      }
    }

    // Sort everything by name
    joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));

    return joinedItems;
  }

  Optional<JoinedItem> get(String upc) {
    final item = itemDatabase.get(upc);
    final inventory = inventoryDatabase.get(upc);

    if (item.isPresent && inventory.isPresent) {
      return Optional.of(JoinedItem(item.value, inventory.value));
    } else {
      return const Optional.absent();
    }
  }

  List<JoinedItem> filter(Filter filter) {
    List<Item> results = itemDatabase.filter(filter);
    List<JoinedItem> joinedItems = [];

    for (final item in results) {
      final inventory = inventoryDatabase.get(item.upc);

      if (inventory.isPresent) {
        joinedItems.add(JoinedItem(item, inventory.value));
      }
    }

    // Sort everything by name
    joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));

    return joinedItems;
  }

  List<JoinedItem> outs() {
    List<Inventory> inventoryOuts = inventoryDatabase.outs();
    List<JoinedItem> joinedItems = [];

    for (final inventory in inventoryOuts) {
      final item = itemDatabase.get(inventory.upc);

      if (item.isPresent) {
        joinedItems.add(JoinedItem(item.value, inventory));
      }
    }

    return joinedItems;
  }

  List<JoinedItem> predictedOuts(HistoryDatabase historyDb, {int days = 12}) {
    Set<String> predicted = historyDb.predictedOuts(days);
    return getAll(predicted.toList());
  }

  List<JoinedItem> getAll(List<String> upcs) {
    List<Item> items = itemDatabase.getAll(upcs);
    List<Inventory> inventory = inventoryDatabase.getAll(upcs);
    List<JoinedItem> joinedItems = [];

    for (int i = 0; i < items.length; i++) {
      joinedItems.add(JoinedItem(items[i], inventory[i]));
    }

    return joinedItems;
  }
}
