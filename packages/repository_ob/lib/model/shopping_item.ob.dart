// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxShoppingItem extends ObjectBoxModel<ShoppingItem> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  @Unique(onConflict: ConflictStrategy.replace)
  late String uid;
  late String upc;
  late String name;
  late String category;
  late double price;
  late int quantity;
  late bool checked;
  late String listName;
  ObjectBoxShoppingItem();
  ObjectBoxShoppingItem.from(ShoppingItem original) {
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
