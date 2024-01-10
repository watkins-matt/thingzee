// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unitCount: json['unitCount'] as int? ?? 1,
      lastUpdate: _$JsonConverterFromJson<int, DateTime?>(
          json['lastUpdate'], const NullableDateTimeSerializer().fromJson),
      expirationDates: (json['expirationDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      restock: json['restock'] as bool? ?? true,
      upc: json['upc'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime?>(
          json['updated'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'updated': const NullableDateTimeSerializer().toJson(instance.updated),
      'amount': instance.amount,
      'unitCount': instance.unitCount,
      'lastUpdate':
          const NullableDateTimeSerializer().toJson(instance.lastUpdate),
      'expirationDates':
          instance.expirationDates.map((e) => e.toIso8601String()).toList(),
      'locations': instance.locations,
      'restock': instance.restock,
      'uid': instance.uid,
      'upc': instance.upc,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
