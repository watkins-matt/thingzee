// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item()
  ..upc = json['upc'] as String
  ..id = json['id'] as String
  ..name = json['name'] as String
  ..variety = json['variety'] as String
  ..category = json['category'] as String
  ..type = json['type'] as String
  ..unitCount = json['unitCount'] as int
  ..unitName = json['unitName'] as String
  ..unitPlural = json['unitPlural'] as String
  ..imageUrl = json['imageUrl'] as String
  ..consumable = json['consumable'] as bool
  ..languageCode = json['languageCode'] as String
  ..lastUpdate = _$JsonConverterFromJson<int, DateTime?>(
      json['lastUpdate'], const NullableDateTimeSerializer().fromJson);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'upc': instance.upc,
      'id': instance.id,
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
      'lastUpdate':
          const NullableDateTimeSerializer().toJson(instance.lastUpdate),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

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
