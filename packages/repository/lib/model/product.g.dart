// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      name: json['name'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      manufacturerUid: json['manufacturerUid'] as String? ?? '',
      category: json['category'] as String? ?? '',
      upcs:
          (json['upcs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      created: _$JsonConverterFromJson<int, DateTime>(
          json['created'], const DateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime>(
          json['updated'], const DateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'created': const DateTimeSerializer().toJson(instance.created),
      'updated': const DateTimeSerializer().toJson(instance.updated),
      'name': instance.name,
      'uid': instance.uid,
      'manufacturer': instance.manufacturer,
      'manufacturerUid': instance.manufacturerUid,
      'category': instance.category,
      'upcs': instance.upcs,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
