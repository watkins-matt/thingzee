// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiration_date.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpirationDate _$ExpirationDateFromJson(Map<String, dynamic> json) =>
    ExpirationDate(
      upc: json['upc'] as String? ?? '',
      date: _$JsonConverterFromJson<int, DateTime?>(
          json['date'], const NullableDateTimeSerializer().fromJson),
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ExpirationDateToJson(ExpirationDate instance) =>
    <String, dynamic>{
      'upc': instance.upc,
      'date': const NullableDateTimeSerializer().toJson(instance.date),
      'created': const NullableDateTimeSerializer().toJson(instance.created),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
