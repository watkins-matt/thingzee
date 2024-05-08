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
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    languageCode = original.languageCode;
    name = original.name;
    variety = original.variety;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    type = original.type;
  }
  ItemTranslation convert() {
    return ItemTranslation(
        created: created,
        updated: updated,
        upc: upc,
        languageCode: languageCode,
        name: name,
        variety: variety,
        unitName: unitName,
        unitPlural: unitPlural,
        type: type);
  }
}
