import 'package:fuzzy/fuzzy.dart';
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

      if (item != null) {
        joinedItems.add(JoinedItem(item, inventory));
      }
    }

    // Sort everything by name
    joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));

    return joinedItems;
  }

  List<JoinedItem> filter(Filter filter) {
    List<Item> results = itemDatabase.filter(filter);
    List<JoinedItem> joinedItems = [];

    for (final item in results) {
      final inventory = inventoryDatabase.get(item.upc);

      if (inventory != null) {
        // If we're only showing outs, skip anything that has inventory
        if (filter.outsOnly && inventory.amount > 0) {
          continue;
        }

        joinedItems.add(JoinedItem(item, inventory));
      }
    }

    // Sort by alphabetically name if we are using branded names
    if (filter.displayBranded) {
      joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));
    }
    // Without branded names, we need to sort by type if available
    else {
      joinedItems.sort((a, b) {
        final typeA = a.item.type;
        final typeB = b.item.type;
        if (typeA.isEmpty) {
          return typeB.isEmpty ? a.item.name.compareTo(b.item.name) : 1;
        }
        if (typeB.isEmpty) {
          return -1;
        }
        return typeA.compareTo(typeB);
      });
    }

    return joinedItems;
  }

  List<JoinedItem> fuzzySearch(String query) {
    List<JoinedItem> allItems = all();

    // If the query is empty, return all items.
    if (query.isEmpty) {
      return allItems;
    }

    // Prepare the list of names for fuzzy searching.
    List<String> itemNames = allItems.map((e) => e.item.name).toList();

    final options = FuzzyOptions(
      findAllMatches: true,
      threshold: 0.3,
      isCaseSensitive: false,
    );

    // Initialize Fuzzy with the list of item names.
    final fuzzy = Fuzzy(itemNames, options: options);

    // Perform the search.
    final result = fuzzy.search(query);

    // Prepare a map for quick lookup from item name to a list of JoinedItems.
    Map<String, List<JoinedItem>> nameToItemsMap = {};
    for (final item in allItems) {
      nameToItemsMap.putIfAbsent(item.item.name, () => []).add(item);
    }

    // Map the results back to JoinedItems using the item name for lookup.
    List<JoinedItem> matchedItems = [];
    for (final r in result) {
      String matchedName = r.item; // The matched item name.
      // Check if the matched name exists in the map and add all corresponding JoinedItems to the results.
      List<JoinedItem>? items = nameToItemsMap[matchedName];
      if (items != null) {
        matchedItems.addAll(items);
      }
    }

    return matchedItems;
  }

  JoinedItem? get(String upc) {
    final item = itemDatabase.get(upc);
    final inventory = inventoryDatabase.get(upc);

    if (item != null && inventory != null) {
      return JoinedItem(item, inventory);
    } else {
      return null;
    }
  }

  /// Returns a list of JoinedItems for the given UPCs.
  /// If innerJoin is true, only items with corresponding inventory objects
  /// will be returned.
  List<JoinedItem> getAll(List<String> upcs, {bool innerJoin = true}) {
    List<Item> items = itemDatabase.getAll(upcs);
    final inventoryMap = inventoryDatabase.map();
    List<JoinedItem> joinedItems = [];

    for (int i = 0; i < items.length; i++) {
      final upc = items[i].upc;

      // There may be cases where the item exists, but doesn't have inventory
      // As long as innerJoin is true, we only return items that have
      // a corresponding inventory object.
      if (inventoryMap.containsKey(upc)) {
        final inventory = inventoryMap[upc]!;
        joinedItems.add(JoinedItem(items[i], inventory));
      }

      // If innerJoin is false, we return the item with an empty inventory
      else if (!innerJoin) {
        joinedItems.add(JoinedItem(items[i], Inventory.withUPC(upc)));
      }
    }

    return joinedItems;
  }

  List<JoinedItem> outs() {
    List<Inventory> inventoryOuts = inventoryDatabase.outs();
    List<JoinedItem> joinedItems = [];

    for (final inventory in inventoryOuts) {
      final item = itemDatabase.get(inventory.upc);

      if (item != null) {
        joinedItems.add(JoinedItem(item, inventory));
      }
    }

    return joinedItems;
  }

  List<JoinedItem> predictedOuts(HistoryDatabase historyDb, {int days = 12}) {
    Set<String> predicted = historyDb.predictedOuts(days: days);
    return getAll(predicted.toList());
  }

  List<JoinedItem> search(String string) {
    List<Item> results = itemDatabase.search(string);
    List<JoinedItem> joinedItems = [];

    for (final item in results) {
      final inventory = inventoryDatabase.get(item.upc);

      if (inventory != null) {
        joinedItems.add(JoinedItem(item, inventory));
      }
    }

    // Sort everything by name
    joinedItems.sort((a, b) => a.item.name.compareTo(b.item.name));

    return joinedItems;
  }
}
