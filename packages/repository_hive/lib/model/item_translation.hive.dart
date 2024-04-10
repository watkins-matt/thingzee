// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/item_translation.dart';

part 'item_translation.hive.g.dart';

@HiveType(typeId: 0)
class HiveItemTranslation extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late String languageCode;
  @HiveField(4)
  late String name;
  @HiveField(5)
  late String variety;
  @HiveField(6)
  late String unitName;
  @HiveField(7)
  late String unitPlural;
  @HiveField(8)
  late String type;
  HiveItemTranslation();
  HiveItemTranslation.from(ItemTranslation original) {
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
