import 'package:hive/hive.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_hive/model/inventory.hive.dart';

class HiveInventoryDatabase extends InventoryDatabase {
  late Box<HiveInventory> box;

  HiveInventoryDatabase() {
    box = Hive.box<HiveInventory>('inventory');
  }

  @override
  List<Inventory> all() {
    final all = box.values.toList();
    return all.map((hiveInventory) => hiveInventory.convert()).toList();
  }

  @override
  void delete(Inventory inv) {
    box.delete(inv.upc);
  }

  @override
  void deleteAll() {
    box.clear();
  }

  @override
  void deleteById(String id) {
    box.delete(id);
  }

  @override
  Inventory? get(String upc) {
    final existingInventory = box.get(upc);
    return existingInventory?.convert();
  }

  @override
  List<Inventory> getAll(List<String> upcs) {
    final matchingInventory =
        box.values.where((hiveInventory) => upcs.contains(hiveInventory.upc)).toList();
    return matchingInventory.map((hiveInventory) => hiveInventory.convert()).toList();
  }

  @override
  List<Inventory> getChanges(DateTime since) {
    final changedItems =
        box.values.where((hiveInventory) => hiveInventory.updated.isAfter(since)).toList();
    return changedItems.map((hiveInventory) => hiveInventory.convert()).toList();
  }

  @override
  Map<String, Inventory> map() {
    final inventoryMap = <String, Inventory>{};
    final allInventory = all();

    for (final inv in allInventory) {
      inventoryMap[inv.upc] = inv;
    }

    return inventoryMap;
  }

  @override
  List<Inventory> outs() {
    final outsInventory = box.values
        .where((hiveInventory) => hiveInventory.amount <= 0 && hiveInventory.restock)
        .toList();
    return outsInventory.map((hiveInventory) => hiveInventory.convert()).toList();
  }

  @override
  void put(Inventory inv) {
    assert(inv.upc.isNotEmpty);
    final hiveInventory = HiveInventory.from(inv);
    box.put(inv.upc, hiveInventory);
  }
}
