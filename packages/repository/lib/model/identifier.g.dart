// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Identifier _$IdentifierFromJson(Map<String, dynamic> json) => Identifier(
      type: json['type'] as String? ?? '',
      value: json['value'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime?>(
          json['updated'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$IdentifierToJson(Identifier instance) =>
    <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'updated': const NullableDateTimeSerializer().toJson(instance.updated),
      'type': instance.type,
      'value': instance.value,
      'uid': instance.uid,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
