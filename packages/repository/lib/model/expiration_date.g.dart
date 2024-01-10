// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiration_date.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpirationDate _$ExpirationDateFromJson(Map<String, dynamic> json) =>
    ExpirationDate(
      upc: json['upc'] as String? ?? '',
      expirationDate: _$JsonConverterFromJson<int, DateTime?>(
          json['expirationDate'], const NullableDateTimeSerializer().fromJson),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['updated'] as String),
    );

Map<String, dynamic> _$ExpirationDateToJson(ExpirationDate instance) =>
    <String, dynamic>{
      'created': instance.created?.toIso8601String(),
      'updated': instance.updated?.toIso8601String(),
      'upc': instance.upc,
      'expirationDate':
          const NullableDateTimeSerializer().toJson(instance.expirationDate),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
