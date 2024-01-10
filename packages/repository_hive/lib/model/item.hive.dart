import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/item.dart';

part 'item.hive.g.dart';

@HiveType(typeId: 0)
class HiveItem extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late String id;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late String variety;
  @HiveField(4)
  late String category;
  @HiveField(5)
  late String type;
  @HiveField(6)
  late String typeId;
  @HiveField(7)
  late int unitCount;
  @HiveField(8)
  late String unitName;
  @HiveField(9)
  late String unitPlural;
  @HiveField(10)
  late String imageUrl;
  @HiveField(11)
  late bool consumable;
  @HiveField(12)
  late String languageCode;
  @HiveField(13)
  late DateTime? lastUpdate;
  HiveItem();
  HiveItem.from(Item original) {
    upc = original.upc;
    id = original.id;
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
    lastUpdate = original.lastUpdate;
  }
  Item toItem() {
    return Item()
      ..upc = upc
      ..id = id
      ..name = name
      ..variety = variety
      ..category = category
      ..type = type
      ..typeId = typeId
      ..unitCount = unitCount
      ..unitName = unitName
      ..unitPlural = unitPlural
      ..imageUrl = imageUrl
      ..consumable = consumable
      ..languageCode = languageCode
      ..lastUpdate = lastUpdate;
  }
}

@HiveType(typeId: 0)
class HiveItemTranslation extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late String languageCode;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late String variety;
  @HiveField(4)
  late String unitName;
  @HiveField(5)
  late String unitPlural;
  @HiveField(6)
  late String type;
  HiveItemTranslation();
  HiveItemTranslation.from(ItemTranslation original) {
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
