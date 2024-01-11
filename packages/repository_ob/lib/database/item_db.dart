import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/model/item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxItemDatabase extends ItemDatabase {
  late Box<ObjectBoxItem> box;

  ObjectBoxItemDatabase(Store store) {
    box = store.box<ObjectBoxItem>();
  }

  @override
  List<Item> all() {
    final all = box.getAll();
    return all.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  void delete(Item item) {
    final query = box.query(ObjectBoxItem_.upc.equals(item.upc)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  void deleteById(String id) {
    final query = box.query(ObjectBoxItem_.upc.equals(id)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  List<Item> filter(Filter filter) {
    final query = box.query(filter.toObjectBoxItemCondition()).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  Item? get(String upc) {
    final query = box.query(ObjectBoxItem_.upc.equals(upc)).build();
    var result = query.findFirst()?.toItem();
    query.close();

    return result;
  }

  @override
  List<Item> getAll(List<String> upcs) {
    final query = box.query(ObjectBoxItem_.upc.oneOf(upcs)).build();
    final results = query.find();
    query.close();

    // Convert to list of Item objects
    var itemList = results.map((objBoxItem) => objBoxItem.toItem()).toList();
    return itemList;
  }

  @override
  List<Item> getChanges(DateTime since) {
    final query =
        box.query(ObjectBoxItem_.updated.greaterThan(since.millisecondsSinceEpoch)).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  Map<String, Item> map() {
    Map<String, Item> map = {};
    final allItems = all();

    for (final inv in allItems) {
      map[inv.upc] = inv;
    }

    return map;
  }

  // Find the product info and replace with our new info. We have to find the id of the old
  // object to update correctly.
  @override
  void put(Item item) {
    assert(item.upc.isNotEmpty && item.name.isNotEmpty);
    final itemOb = ObjectBoxItem.from(item);

    final query = box.query(ObjectBoxItem_.upc.equals(item.upc)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && itemOb.objectBoxId != exists.objectBoxId) {
      itemOb.objectBoxId = exists.objectBoxId;
    }

    box.put(itemOb);
  }

  @override
  List<Item> search(String string) {
    final query = box.query(ObjectBoxItem_.name.contains(string, caseSensitive: false)).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }
}

extension ObjectBoxCondition on Filter {
  Condition<ObjectBoxItem>? toObjectBoxItemCondition() {
    // If both consumable and nonConsumable are true, return everything
    if (consumable && nonConsumable) {
      return null;
    }
    // Only the consumable items
    else if (consumable) {
      return ObjectBoxItem_.consumable.equals(true);
    }
    // Only the non-consumable
    else if (nonConsumable) {
      return ObjectBoxItem_.consumable.equals(false);
    }
    // Neither consumable nor nonConsumable is true, default to everything.
    else {
      return null;
    }
  }
}
