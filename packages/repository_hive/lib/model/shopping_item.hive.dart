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
  late String uid;
  @HiveField(3)
  late String upc;
  @HiveField(4)
  late String name;
  @HiveField(5)
  late String category;
  @HiveField(6)
  late double price;
  @HiveField(7)
  late int quantity;
  @HiveField(8)
  late bool checked;
  @HiveField(9)
  late String listName;
  HiveShoppingItem();
  HiveShoppingItem.from(ShoppingItem original) {
    created = original.created;
    updated = original.updated;
    uid = original.uid;
    upc = original.upc;
    name = original.name;
    category = original.category;
    price = original.price;
    quantity = original.quantity;
    checked = original.checked;
    listName = original.listName;
  }
  ShoppingItem convert() {
    return ShoppingItem(
        created: created,
        updated: updated,
        uid: uid,
        upc: upc,
        name: name,
        category: category,
        price: price,
        quantity: quantity,
        checked: checked,
        listName: listName);
  }
}
