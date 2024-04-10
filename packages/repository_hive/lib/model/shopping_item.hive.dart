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
  late String name;
  @HiveField(4)
  late String category;
  @HiveField(5)
  late double price;
  @HiveField(6)
  late bool checked;
  @HiveField(7)
  late String listName;
  HiveShoppingItem();
  HiveShoppingItem.from(ShoppingItem original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    name = original.name;
    category = original.category;
    price = original.price;
    checked = original.checked;
    listName = original.listName;
  }
  ShoppingItem convert() {
    return ShoppingItem(
        created: created,
        updated: updated,
        upc: upc,
        name: name,
        category: category,
        price: price,
        checked: checked,
        listName: listName);
  }
}
