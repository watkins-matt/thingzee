import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/shopping_item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxShoppingListDatabase extends ShoppingListDatabase
    with ObjectBoxDatabase<ShoppingItem, ObjectBoxShoppingItem> {
  ObjectBoxShoppingListDatabase(Store store) {
    init(store, ObjectBoxShoppingItem.from, ObjectBoxShoppingItem_.uid,
        ObjectBoxShoppingItem_.updated);
  }
}
