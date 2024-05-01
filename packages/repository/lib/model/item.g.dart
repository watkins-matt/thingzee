// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      upc: json['upc'] as String? ?? '',
      uid: json['uid'] as String?,
      name: json['name'] as String? ?? '',
      variety: json['variety'] as String? ?? '',
      category: json['category'] as String? ?? '',
      type: json['type'] as String? ?? '',
      typeId: json['typeId'] as String? ?? '',
      unitCount: json['unitCount'] as int? ?? 1,
      unitName: json['unitName'] as String? ?? '',
      unitPlural: json['unitPlural'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      consumable: json['consumable'] as bool? ?? true,
      languageCode: json['languageCode'] as String? ?? 'en',
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'upc': instance.upc,
      'uid': instance.uid,
      'name': instance.name,
      'variety': instance.variety,
      'category': instance.category,
      'type': instance.type,
      'typeId': instance.typeId,
      'unitCount': instance.unitCount,
      'unitName': instance.unitName,
      'unitPlural': instance.unitPlural,
      'imageUrl': instance.imageUrl,
      'consumable': instance.consumable,
      'languageCode': instance.languageCode,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
