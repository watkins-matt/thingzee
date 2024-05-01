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
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ExpirationDateToJson(ExpirationDate instance) =>
    <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'upc': instance.upc,
      'expirationDate':
          const NullableDateTimeSerializer().toJson(instance.expirationDate),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
