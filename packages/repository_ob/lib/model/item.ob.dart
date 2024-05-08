// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxItem extends ObjectBoxModel<Item> {
  @Id()
  int objectBoxId = 0;
  late bool consumable;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late int unitCount;
  late String category;
  late String imageUrl;
  late String languageCode;
  late String name;
  late String type;
  late String typeId;
  late String uid;
  late String unitName;
  late String unitPlural;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  late String variety;
  ObjectBoxItem();
  ObjectBoxItem.from(Item original) {
    category = original.category;
    consumable = original.consumable;
    created = original.created;
    imageUrl = original.imageUrl;
    languageCode = original.languageCode;
    name = original.name;
    type = original.type;
    typeId = original.typeId;
    uid = original.uid;
    unitCount = original.unitCount;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    upc = original.upc;
    updated = original.updated;
    variety = original.variety;
  }
  Item convert() {
    return Item(
        category: category,
        consumable: consumable,
        created: created,
        imageUrl: imageUrl,
        languageCode: languageCode,
        name: name,
        type: type,
        typeId: typeId,
        uid: uid,
        unitCount: unitCount,
        unitName: unitName,
        unitPlural: unitPlural,
        upc: upc,
        updated: updated,
        variety: variety);
  }
}
