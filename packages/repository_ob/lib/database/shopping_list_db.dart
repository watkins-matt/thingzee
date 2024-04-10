import 'package:repository/database/shopping_list.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/shopping_item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxShoppingListDatabase extends ShoppingListDatabase
    with ObjectBoxDatabase<ShoppingItem, ObjectBoxShoppingItem> {
  ObjectBoxShoppingListDatabase(Store store) {
    constructDb(store);
  }

  @override
  Condition<ObjectBoxShoppingItem> buildIdCondition(String id) {
    return ObjectBoxShoppingItem_.upc.equals(id);
  }

  @override
  Condition<ObjectBoxShoppingItem> buildIdsCondition(List<String> ids) {
    return ObjectBoxShoppingItem_.upc.oneOf(ids);
  }

  @override
  Condition<ObjectBoxShoppingItem> buildSinceCondition(DateTime since) {
    return ObjectBoxShoppingItem_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxShoppingItem fromModel(ShoppingItem model) => ObjectBoxShoppingItem.from(model);
}
