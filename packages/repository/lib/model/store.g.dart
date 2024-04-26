// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Store _$StoreFromJson(Map<String, dynamic> json) => Store(
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipcode: json['zipcode'] as String? ?? '',
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime?>(
          json['updated'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$StoreToJson(Store instance) => <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'updated': const NullableDateTimeSerializer().toJson(instance.updated),
      'phoneNumber': instance.phoneNumber,
      'name': instance.name,
      'city': instance.city,
      'state': instance.state,
      'zipcode': instance.zipcode,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
