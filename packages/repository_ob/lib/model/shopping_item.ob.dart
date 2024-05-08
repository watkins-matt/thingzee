// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxShoppingItem extends ObjectBoxModel<ShoppingItem> {
  @Id()
  int objectBoxId = 0;
  late bool checked;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late double price;
  late int quantity;
  late String category;
  late String listName;
  late String name;
  @Unique(onConflict: ConflictStrategy.replace)
  late String uid;
  late String upc;
  ObjectBoxShoppingItem();
  ObjectBoxShoppingItem.from(ShoppingItem original) {
    category = original.category;
    checked = original.checked;
    created = original.created;
    listName = original.listName;
    name = original.name;
    price = original.price;
    quantity = original.quantity;
    uid = original.uid;
    upc = original.upc;
    updated = original.updated;
  }
  ShoppingItem convert() {
    return ShoppingItem(
        category: category,
        checked: checked,
        created: created,
        listName: listName,
        name: name,
        price: price,
        quantity: quantity,
        uid: uid,
        upc: upc,
        updated: updated);
  }
}
