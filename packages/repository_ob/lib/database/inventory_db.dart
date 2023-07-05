import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/model/inventory.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxInventoryDatabase extends InventoryDatabase {
  late Box<ObjectBoxInventory> box;

  ObjectBoxInventoryDatabase(Store store) {
    box = store.box<ObjectBoxInventory>();
  }

  @override
  List<Inventory> all() {
    final all = box.getAll();
    return all.map((objBoxInv) => objBoxInv.toInventory()).toList();
  }

  @override
  void delete(Inventory inv) {
    assert(inv.upc.isNotEmpty);
    final query = box.query(ObjectBoxInventory_.upc.equals(inv.upc)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.id);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  Inventory? get(String upc) {
    assert(upc.isNotEmpty);
    final query = box.query(ObjectBoxInventory_.upc.equals(upc)).build();
    var result = query.findFirst()?.toInventory();
    query.close();

    return result;
  }

  @override
  List<Inventory> getAll(List<String> upcs) {
    if (upcs.isEmpty) {
      return [];
    }

    final query = box.query(ObjectBoxInventory_.upc.oneOf(upcs)).build();
    final results = query.find();
    query.close();

    // Convert to list of Inventory objects
    var inventoryList = results.map((objBoxInv) => objBoxInv.toInventory()).toList();
    return inventoryList;
  }

  @override
  List<Inventory> getChanges(DateTime since) {
    final query =
        box.query(ObjectBoxInventory_.lastUpdate.greaterThan(since.millisecondsSinceEpoch)).build();
    final results = query.find();
    return results.map((objBoxInv) => objBoxInv.toInventory()).toList();
  }

  @override
  Map<String, Inventory> map() {
    Map<String, Inventory> map = {};
    final allInventory = all();

    for (final inv in allInventory) {
      map[inv.upc] = inv;
    }

    return map;
  }

  @override
  List<Inventory> outs() {
    final query = box
        .query(
            ObjectBoxInventory_.amount.lessOrEqual(0).and(ObjectBoxInventory_.restock.equals(true)))
        .build();

    final results = query.find();
    query.close();

    // Convert to list of Inventory objects
    var outs = results.map((objBoxInv) => objBoxInv.toInventory()).toList();
    return outs;
  }

  // Find the product info and replace with our new info. We have to find the id of the old
  // object to update correctly.
  @override
  void put(Inventory inv) {
    assert(inv.upc.isNotEmpty);
    final invOb = ObjectBoxInventory.from(inv);

    final query = box.query(ObjectBoxInventory_.upc.equals(inv.upc)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && invOb.id != exists.id) {
      invOb.id = exists.id;
    }

    box.put(invOb);
  }
}
