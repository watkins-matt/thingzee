// ignore_for_file: avoid_renaming_method_parameters

import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxItemDatabase extends ItemDatabase with ObjectBoxDatabase<Item, ObjectBoxItem> {
  ObjectBoxItemDatabase(Store store) {
    init(store, ObjectBoxItem.from, ObjectBoxItem_.upc, ObjectBoxItem_.updated);
  }

  @override
  List<Item> filter(Filter filter) {
    final query = box.query(filter.toObjectBoxItemCondition()).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.convert()).toList();
  }

  @override
  List<Item> search(String string) {
    final query = box.query(ObjectBoxItem_.name.contains(string, caseSensitive: false)).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.convert()).toList();
  }
}

extension ObjectBoxCondition on Filter {
  Condition<ObjectBoxItem>? toObjectBoxItemCondition() {
    if (consumable && nonConsumable) {
      return null;
    } else if (consumable) {
      return ObjectBoxItem_.consumable.equals(true);
    } else if (nonConsumable) {
      return ObjectBoxItem_.consumable.equals(false);
    } else {
      return null;
    }
  }
}
