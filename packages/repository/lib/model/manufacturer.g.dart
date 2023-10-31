// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manufacturer _$ManufacturerFromJson(Map<String, dynamic> json) => Manufacturer()
  ..name = json['name'] as String
  ..website = json['website'] as String
  ..uid = json['uid'] as String
  ..parentName = json['parentName'] as String
  ..parentUid = json['parentUid'] as String;

Map<String, dynamic> _$ManufacturerToJson(Manufacturer instance) => <String, dynamic>{
      'name': instance.name,
      'website': instance.website,
      'muid': instance.uid,
      'parentName': instance.parentName,
      'parentUid': instance.parentUid,
    };
