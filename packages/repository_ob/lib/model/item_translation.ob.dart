// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/item_translation.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxItemTranslation extends ObjectBoxModel<ItemTranslation> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String languageCode;
  late String name;
  late String type;
  late String unitName;
  late String unitPlural;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  late String variety;
  ObjectBoxItemTranslation();
  ObjectBoxItemTranslation.from(ItemTranslation original) {
    created = original.created;
    languageCode = original.languageCode;
    name = original.name;
    type = original.type;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    upc = original.upc;
    updated = original.updated;
    variety = original.variety;
  }
  ItemTranslation convert() {
    return ItemTranslation(
        created: created,
        languageCode: languageCode,
        name: name,
        type: type,
        unitName: unitName,
        unitPlural: unitPlural,
        upc: upc,
        updated: updated,
        variety: variety);
  }
}
