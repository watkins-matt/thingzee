// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_translation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemTranslation _$ItemTranslationFromJson(Map<String, dynamic> json) =>
    ItemTranslation(
      upc: json['upc'] as String? ?? '',
      languageCode: json['languageCode'] as String? ?? 'en',
      name: json['name'] as String? ?? '',
      variety: json['variety'] as String? ?? '',
      unitName: json['unitName'] as String? ?? '',
      unitPlural: json['unitPlural'] as String? ?? '',
      type: json['type'] as String? ?? '',
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ItemTranslationToJson(ItemTranslation instance) =>
    <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'upc': instance.upc,
      'languageCode': instance.languageCode,
      'name': instance.name,
      'variety': instance.variety,
      'unitName': instance.unitName,
      'unitPlural': instance.unitPlural,
      'type': instance.type,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
