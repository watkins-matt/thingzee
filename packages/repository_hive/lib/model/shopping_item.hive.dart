// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/shopping_item.dart';

part 'shopping_item.hive.g.dart';

@HiveType(typeId: 0)
class HiveShoppingItem extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late bool checked;
  @HiveField(4)
  late ShoppingListType listType;
  HiveShoppingItem();
  HiveShoppingItem.from(ShoppingItem original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    checked = original.checked;
    listType = original.listType;
  }
  ShoppingItem toShoppingItem() {
    return ShoppingItem(
        created: created,
        updated: updated,
        upc: upc,
        checked: checked,
        listType: listType);
  }
}
