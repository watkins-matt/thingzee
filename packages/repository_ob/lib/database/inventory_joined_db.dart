import 'package:objectbox/objectbox.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/database/inventory_db.dart';

class ObjectBoxJoinedInventoryDatabase extends ObjectBoxInventoryDatabase {
  final HistoryDatabase historyDb;

  ObjectBoxJoinedInventoryDatabase(Store store, this.historyDb) : super(store);

  @override
  List<Inventory> all() {
    final all = box.getAll();
    var inventoryList = all.map((objBoxInv) => objBoxInv.toInventory()).toList();
    inventoryList = historyDb.joinList(inventoryList);

    return inventoryList;
  }

  @override
  Optional<Inventory> get(String upc) {
    final inventory = super.get(upc);

    // If we found inventory, add the history from the database
    if (inventory.isPresent) {
      final history = historyDb.get(upc);

      // History exists, add to inventory
      if (history != null) {
        inventory.value.history = history;

        // Initialize a default history with the current upc
      } else {
        final newHistory = History()..upc = upc;
        inventory.value.history = newHistory;
      }
    }

    return inventory;
  }

  @override
  List<Inventory> getAll(List<String> upcs) {
    var inventoryList = super.getAll(upcs);
    inventoryList = historyDb.joinList(inventoryList);
    return inventoryList;
  }

  @override
  Map<String, Inventory> map() {
    var map = super.map();
    map = historyDb.join(map);
    return map;
  }

  @override
  List<Inventory> outs() {
    final outs = super.outs();
    return historyDb.joinList(outs);
  }

  @override
  void put(Inventory inv) {
    assert(inv.upc.isNotEmpty && inv.history.upc == inv.upc);
    super.put(inv);
    historyDb.put(inv.history);
  }
}
