// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      upc: json['upc'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime?>(
          json['updated'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'updated': const NullableDateTimeSerializer().toJson(instance.updated),
      'upc': instance.upc,
      'name': instance.name,
      'quantity': instance.quantity,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
