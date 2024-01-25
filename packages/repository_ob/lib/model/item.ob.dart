// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/item.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxItem extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  late String uid;
  late String name;
  late String variety;
  late String category;
  late String type;
  late String typeId;
  late int unitCount;
  late String unitName;
  late String unitPlural;
  late String imageUrl;
  late bool consumable;
  late String languageCode;
  ObjectBoxItem();
  ObjectBoxItem.from(Item original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    uid = original.uid;
    name = original.name;
    variety = original.variety;
    category = original.category;
    type = original.type;
    typeId = original.typeId;
    unitCount = original.unitCount;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    imageUrl = original.imageUrl;
    consumable = original.consumable;
    languageCode = original.languageCode;
  }
  Item toItem() {
    return Item(
        created: created,
        updated: updated,
        upc: upc,
        uid: uid,
        name: name,
        variety: variety,
        category: category,
        type: type,
        typeId: typeId,
        unitCount: unitCount,
        unitName: unitName,
        unitPlural: unitPlural,
        imageUrl: imageUrl,
        consumable: consumable,
        languageCode: languageCode);
  }
}

@Entity()
class ObjectBoxItemTranslation extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  late String languageCode;
  late String name;
  late String variety;
  late String unitName;
  late String unitPlural;
  late String type;
  ObjectBoxItemTranslation();
  ObjectBoxItemTranslation.from(ItemTranslation original) {
    upc = original.upc;
    languageCode = original.languageCode;
    name = original.name;
    variety = original.variety;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    type = original.type;
  }
  ItemTranslation toItemTranslation() {
    return ItemTranslation()
      ..upc = upc
      ..languageCode = languageCode
      ..name = name
      ..variety = variety
      ..unitName = unitName
      ..unitPlural = unitPlural
      ..type = type;
  }
}
