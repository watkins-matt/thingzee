import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxItemDatabase extends ItemDatabase with ObjectBoxDatabase<Item, ObjectBoxItem> {
  ObjectBoxItemDatabase(Store store) {
    constructDb(store);
  }

  // Implement filter and search methods as they are specific to ItemDatabase
  @override
  List<Item> filter(Filter filter) {
    final query = box.query(filter.toObjectBoxItemCondition()).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  ObjectBoxItem fromModel(Item model) => ObjectBoxItem.from(model);

  @override
  List<Item> search(String string) {
    final query = box.query(ObjectBoxItem_.name.contains(string, caseSensitive: false)).build();
    final results = query.find();
    return results.map((objBoxItem) => objBoxItem.toItem()).toList();
  }

  @override
  Item toModel(ObjectBoxItem objectBoxEntity) => objectBoxEntity.toItem();

  @override
  Condition<ObjectBoxItem> _buildIdCondition(String upc) {
    return ObjectBoxItem_.upc.equals(upc);
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
