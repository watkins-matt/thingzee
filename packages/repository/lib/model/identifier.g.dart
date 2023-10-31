// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemIdentifier _$ItemIdentifierFromJson(Map<String, dynamic> json) => ItemIdentifier()
  ..type = const IdentifierTypeSerializer().fromJson(json['type'] as String)
  ..uid = json['uid'] as String
  ..value = json['value'] as String;

Map<String, dynamic> _$ItemIdentifierToJson(ItemIdentifier instance) => <String, dynamic>{
      'type': const IdentifierTypeSerializer().toJson(instance.type),
      'uid': instance.uid,
      'value': instance.value,
    };
