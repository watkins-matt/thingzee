// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item()
  ..upc = json['upc'] as String
  ..iuid = json['iuid'] as String
  ..name = json['name'] as String
  ..variety = json['variety'] as String
  ..category = json['category'] as String
  ..type = json['type'] as String
  ..unitCount = json['unitCount'] as int
  ..unitName = json['unitName'] as String
  ..unitPlural = json['unitPlural'] as String
  ..imageUrl = json['imageUrl'] as String
  ..consumable = json['consumable'] as bool
  ..languageCode = json['languageCode'] as String;

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'upc': instance.upc,
      'iuid': instance.iuid,
      'name': instance.name,
      'variety': instance.variety,
      'category': instance.category,
      'type': instance.type,
      'unitCount': instance.unitCount,
      'unitName': instance.unitName,
      'unitPlural': instance.unitPlural,
      'imageUrl': instance.imageUrl,
      'consumable': instance.consumable,
      'languageCode': instance.languageCode,
    };

ItemTranslation _$ItemTranslationFromJson(Map<String, dynamic> json) =>
    ItemTranslation()
      ..upc = json['upc'] as String
      ..languageCode = json['languageCode'] as String
      ..name = json['name'] as String
      ..variety = json['variety'] as String
      ..unitName = json['unitName'] as String
      ..unitPlural = json['unitPlural'] as String;

Map<String, dynamic> _$ItemTranslationToJson(ItemTranslation instance) =>
    <String, dynamic>{
      'upc': instance.upc,
      'languageCode': instance.languageCode,
      'name': instance.name,
      'variety': instance.variety,
      'unitName': instance.unitName,
      'unitPlural': instance.unitPlural,
    };
