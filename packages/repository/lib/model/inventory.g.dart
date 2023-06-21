// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory()
  ..amount = (json['amount'] as num).toDouble()
  ..unitCount = json['unitCount'] as int
  ..lastUpdate =
      const OptDateTimeSerializer().fromJson(json['lastUpdate'] as int)
  ..expirationDates = (json['expirationDates'] as List<dynamic>)
      .map((e) => DateTime.parse(e as String))
      .toList()
  ..locations =
      (json['locations'] as List<dynamic>).map((e) => e as String).toList()
  ..history = History.fromJson(json['history'] as Map<String, dynamic>)
  ..restock = json['restock'] as bool
  ..upc = json['upc'] as String
  ..iuid = json['iuid'] as String
  ..units = (json['units'] as num).toDouble();

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'amount': instance.amount,
      'unitCount': instance.unitCount,
      'lastUpdate': const OptDateTimeSerializer().toJson(instance.lastUpdate),
      'expirationDates':
          instance.expirationDates.map((e) => e.toIso8601String()).toList(),
      'locations': instance.locations,
      'history': instance.history.toJson(),
      'restock': instance.restock,
      'upc': instance.upc,
      'iuid': instance.iuid,
      'units': instance.units,
    };
