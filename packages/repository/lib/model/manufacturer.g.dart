// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manufacturer _$ManufacturerFromJson(Map<String, dynamic> json) => Manufacturer()
  ..name = json['name'] as String
  ..website = json['website'] as String
  ..muid = json['muid'] as String
  ..parentName = json['parentName'] as String
  ..parentMuid = json['parentMuid'] as String;

Map<String, dynamic> _$ManufacturerToJson(Manufacturer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'website': instance.website,
      'muid': instance.muid,
      'parentName': instance.parentName,
      'parentMuid': instance.parentMuid,
    };
