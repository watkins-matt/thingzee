import 'package:quiver/core.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/model_generated/item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

extension ObjectBoxCondition on Filter {
  Condition<ObjectBoxItem>? toObjectBoxItemCondition() {
    return ObjectBoxItem_.consumable.equals(consumable);
  }
}

class ObjectBoxItemDatabase extends ItemDatabase {
  late Box<ObjectBoxItem> box;

  ObjectBoxItemDatabase(Store store) {
    box = store.box<ObjectBoxItem>();
  }

  @override
  void delete(Item item) {
    final query = box.query(ObjectBoxItem_.upc.equals(item.upc)).build();
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
  List<Item> filter(Filter filter) {
    final query = box.query(filter.toObjectBoxItemCondition()).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  Optional<Item> get(String upc) {
    final query = box.query(ObjectBoxItem_.upc.equals(upc)).build();
    final result = Optional.fromNullable(query.findFirst()?.toItem());
    query.close();

    return result;
  }

  // Find the product info and replace with our new info. We have to find the id of the old
  // object to update correctly.
  @override
  void put(Item item) {
    assert(item.upc.isNotEmpty && item.name.isNotEmpty);
    final itemOb = ObjectBoxItem.from(item);

    final query = box.query(ObjectBoxItem_.upc.equals(item.upc)).build();
    final exists = Optional.fromNullable(query.findFirst());
    query.close();

    if (exists.isPresent && itemOb.id != exists.value.id) {
      itemOb.id = exists.value.id;
    }

    box.put(itemOb);
  }

  @override
  List<Item> search(String string) {
    final query = box.query(ObjectBoxItem_.name.contains(string, caseSensitive: false)).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  List<Item> all() {
    final all = box.getAll();
    return all.map((objBoxItem) => objBoxItem.toItem()).toList();
  }
}
