

import 'package:hive/hive.dart';
import 'package:repository/model/shopping_item.dart';

part 'shopping_item.hive.g.dart';

@HiveType(typeId: 0)
class HiveShoppingItem extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late bool checked;
  @HiveField(2)
  late ShoppingListType listType;
  HiveShoppingItem();
  HiveShoppingItem.from(ShoppingItem original) {
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
