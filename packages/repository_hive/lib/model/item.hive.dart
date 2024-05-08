// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/item.dart';

part 'item.hive.g.dart';

@HiveType(typeId: 0)
class HiveItem extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late String uid;
  @HiveField(4)
  late String name;
  @HiveField(5)
  late String variety;
  @HiveField(6)
  late String category;
  @HiveField(7)
  late String type;
  @HiveField(8)
  late String typeId;
  @HiveField(9)
  late int unitCount;
  @HiveField(10)
  late String unitName;
  @HiveField(11)
  late String unitPlural;
  @HiveField(12)
  late String imageUrl;
  @HiveField(13)
  late bool consumable;
  @HiveField(14)
  late String languageCode;
  HiveItem();
  HiveItem.from(Item original) {
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
