// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxShoppingItem extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
  late String upc;
  late bool checked;
  late ShoppingListType listType;
  ObjectBoxShoppingItem();
  ObjectBoxShoppingItem.from(ShoppingItem original) {
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
