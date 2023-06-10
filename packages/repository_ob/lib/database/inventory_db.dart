import 'package:quiver/core.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/model/inventory.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxInventoryDatabase extends InventoryDatabase {
  late Box<ObjectBoxInventory> box;

  ObjectBoxInventoryDatabase(Store store) {
    box = store.box<ObjectBoxInventory>();
  }

  final List<Function> _callbacks = [];
  void registerGetCallback(Function callback) {
    _callbacks.add(callback);
  }

  @override
  List<Inventory> all() {
    final all = box.getAll();
    return all.map((objBoxInv) => objBoxInv.toInventory()).toList();
  }

  @override
  void delete(Inventory inv) {
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
  Optional<Inventory> get(String upc) {
    final query = box.query(ObjectBoxInventory_.upc.equals(upc)).build();
    var result = Optional.fromNullable(query.findFirst()?.toInventory());
    query.close();

    // Allow processing though callback functions
    if (result.isPresent) {
      for (final callback in _callbacks) {
        result = Optional.fromNullable(callback(result.value));
      }
    }

    return result;
  }

  // @override
  // List<Inventory> outs({bool predicted = false}) {
  // final query =
  //     box.query(Product_.amount.lessOrEqual(0).and(Product_.restock.equals(true))).build();

  // // We only needed the actual outs
  // if (!predicted) {
  //   return query.find();
  // }

  // // Find all predicted outs as well
  // else {
  //   var outs = query.find();

  //   var restockQuery = box
  //       .query(Product_.amount
  //           .greaterOrEqual(0)
  //           .and(Product_.restock.equals(true))
  //           .and(Product_.consumable.equals(true)))
  //       .build();
  //   var restockable = restockQuery.find();

  //   // Whatever date in the future we need to be stocked until
  //   final futureDate = DateTime.now().add(const Duration(days: 12));

  //   for (final product in restockable) {
  //     if (product.canPredictAmount &&
  //         product.predictedOutDate.isBefore(futureDate) &&
  //         !outs.any((element) => element.upc == product.upc)) {
  //       // Extra filter for items that are used quickly
  //       if (product.amount <= 1 && product.predictedAmount <= 0.5) {
  //         outs.add(product);
  //       }
  //     }
  //   }

  //   outs.sort();
  //   return outs;
  // }
  //   return [];
  // }

  // Find the product info and replace with our new info. We have to find the id of the old
  // object to update correctly.
  @override
  void put(Inventory inv) {
    assert(inv.upc.isNotEmpty);
    final invOb = ObjectBoxInventory.from(inv);

    final query = box.query(ObjectBoxInventory_.upc.equals(inv.upc)).build();
    final exists = Optional.fromNullable(query.findFirst());
    query.close();

    if (exists.isPresent && invOb.id != exists.value.id) {
      invOb.id = exists.value.id;
    }

    box.put(invOb);
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
}
