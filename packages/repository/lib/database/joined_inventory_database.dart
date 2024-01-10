import 'package:repository/database/history_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';

class JoinedInventoryDatabase extends InventoryDatabase {
  final InventoryDatabase inventoryDatabase;
  final HistoryDatabase historyDatabase;

  JoinedInventoryDatabase(this.inventoryDatabase, this.historyDatabase);

  @override
  List<Inventory> all() {
    List<Inventory> inventoryList = inventoryDatabase.all();
    inventoryList = historyDatabase.joinList(inventoryList);
    return inventoryList;
  }

  @override
  void delete(Inventory inv) {
    inventoryDatabase.delete(inv);
    // Note that we do not delete this history, the user may need
    // the history information in the future.
  }

  @override
  void deleteAll() {
    inventoryDatabase.deleteAll();
  }

  @override
  Inventory? get(String upc) {
    var inventory = inventoryDatabase.get(upc);

    if (inventory != null) {
      final defaultHistory = History()..upc = upc;
      final history = historyDatabase.get(upc);
      inventory = inventory.copyWith(history: history ?? defaultHistory);
    }

    return inventory;
  }

  @override
  List<Inventory> getAll(List<String> upcs) {
    List<Inventory> inventoryList = inventoryDatabase.getAll(upcs);
    inventoryList = historyDatabase.joinList(inventoryList);
    return inventoryList;
  }

  @override
  List<Inventory> getChanges(DateTime since) {
    var changes = inventoryDatabase.getChanges(since);
    changes = historyDatabase.joinList(changes);
    return changes;
  }

  @override
  Map<String, Inventory> map() {
    Map<String, Inventory> inventoryMap = inventoryDatabase.map();
    inventoryMap = historyDatabase.join(inventoryMap);
    return inventoryMap;
  }

  @override
  List<Inventory> outs() {
    List<Inventory> inventoryOuts = inventoryDatabase.outs();
    inventoryOuts = historyDatabase.joinList(inventoryOuts);
    return inventoryOuts;
  }

  @override
  void put(Inventory inv) {
    assert(inv.upc.isNotEmpty && inv.history.upc == inv.upc);
    inventoryDatabase.put(inv);
    historyDatabase.put(inv.history);
  }
}
