// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_translation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemTranslation _$ItemTranslationFromJson(Map<String, dynamic> json) =>
    ItemTranslation()
      ..upc = json['upc'] as String
      ..languageCode = json['languageCode'] as String
      ..name = json['name'] as String
      ..variety = json['variety'] as String
      ..unitName = json['unitName'] as String
      ..unitPlural = json['unitPlural'] as String
      ..type = json['type'] as String;

Map<String, dynamic> _$ItemTranslationToJson(ItemTranslation instance) =>
    <String, dynamic>{
      'upc': instance.upc,
      'languageCode': instance.languageCode,
      'name': instance.name,
      'variety': instance.variety,
      'unitName': instance.unitName,
      'unitPlural': instance.unitPlural,
      'type': instance.type,
    };
