import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/item.dart';

part 'item.hive.g.dart';
@HiveType(typeId: 2)
class HiveItem extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late String iuid;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late String variety;
  @HiveField(4)
  late String category;
  @HiveField(5)
  late String type;
  @HiveField(6)
  late int unitCount;
  @HiveField(7)
  late String unitName;
  @HiveField(8)
  late String unitPlural;
  @HiveField(9)
  late String imageUrl;
  @HiveField(10)
  late bool consumable;
  @HiveField(11)
  late String languageCode;
  @HiveField(12)
  late List<ItemTranslation> translations;
  HiveItem();
  HiveItem.from(Item original) {
    upc = original.upc;
    iuid = original.iuid;
    name = original.name;
    variety = original.variety;
    category = original.category;
    type = original.type;
    unitCount = original.unitCount;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
    imageUrl = original.imageUrl;
    consumable = original.consumable;
    languageCode = original.languageCode;
    translations = original.translations;
  }
  Item toItem() {
    return Item()
      ..upc = upc
      ..iuid = iuid
      ..name = name
      ..variety = variety
      ..category = category
      ..type = type
      ..unitCount = unitCount
      ..unitName = unitName
      ..unitPlural = unitPlural
      ..imageUrl = imageUrl
      ..consumable = consumable
      ..languageCode = languageCode
      ..translations = translations
    ;
  }
}
@HiveType(typeId: 3)
class HiveItemTranslation extends HiveObject {
  @HiveField(0)
  late String languageCode;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String variety;
  @HiveField(3)
  late String unitName;
  @HiveField(4)
  late String unitPlural;
  HiveItemTranslation();
  HiveItemTranslation.from(ItemTranslation original) {
    languageCode = original.languageCode;
    name = original.name;
    variety = original.variety;
    unitName = original.unitName;
    unitPlural = original.unitPlural;
  }
  ItemTranslation toItemTranslation() {
    return ItemTranslation()
      ..languageCode = languageCode
      ..name = name
      ..variety = variety
      ..unitName = unitName
      ..unitPlural = unitPlural
    ;
  }
}
