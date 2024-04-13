import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/inventory.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxInventoryDatabase extends InventoryDatabase
    with ObjectBoxDatabase<Inventory, ObjectBoxInventory> {
  ObjectBoxInventoryDatabase(Store store) {
    init(store, ObjectBoxInventory.from, ObjectBoxInventory_.upc, ObjectBoxInventory_.updated);
  }

  @override
  List<Inventory> outs() {
    final query = box
        .query(
            ObjectBoxInventory_.amount.lessOrEqual(0).and(ObjectBoxInventory_.restock.equals(true)))
        .build();
    final results = query.find();
    query.close();

    return results.map(convert).toList();
  }
}
