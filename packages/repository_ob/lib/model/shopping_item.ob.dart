

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/shopping_item.dart';

@Entity()
class ObjectBoxShoppingItem {
  late String upc;
  late bool checked;
  late ShoppingListType listType;
  @Id()
  int objectBoxId = 0;
  ObjectBoxShoppingItem();
  ObjectBoxShoppingItem.from(ShoppingItem original) {
    upc = original.upc;
    checked = original.checked;
    listType = original.listType;
  }
  ShoppingItem toShoppingItem() {
    return ShoppingItem(
        upc: upc,
        checked: checked,
        listType: listType);
  }
}
