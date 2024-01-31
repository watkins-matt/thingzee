import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/database/database.dart'; // Adjust the import as needed
import 'package:repository_ob/model/inventory.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxInventoryDatabase extends InventoryDatabase
    with ObjectBoxDatabase<Inventory, ObjectBoxInventory> {
  ObjectBoxInventoryDatabase(Store store) {
    constructDb(store);
  }

  @override
  Condition<ObjectBoxInventory> buildIdCondition(String id) {
    return ObjectBoxInventory_.upc.equals(id);
  }

  @override
  Condition<ObjectBoxInventory> buildIdsCondition(List<String> ids) {
    return ObjectBoxInventory_.upc.oneOf(ids);
  }

  @override
  Condition<ObjectBoxInventory> buildSinceCondition(DateTime since) {
    return ObjectBoxInventory_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxInventory fromModel(Inventory model) => ObjectBoxInventory.from(model);

  @override
  List<Inventory> outs() {
    final query = box
        .query(
            ObjectBoxInventory_.amount.lessOrEqual(0).and(ObjectBoxInventory_.restock.equals(true)))
        .build();
    final results = query.find();
    query.close();

    return results.map(toModel).toList();
  }

  @override
  Inventory toModel(ObjectBoxInventory objectBoxEntity) => objectBoxEntity.toInventory();
}
