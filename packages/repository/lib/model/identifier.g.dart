// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemIdentifier _$ItemIdentifierFromJson(Map<String, dynamic> json) =>
    ItemIdentifier(
      type: json['type'] as String? ?? '',
      value: json['value'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
    );

Map<String, dynamic> _$ItemIdentifierToJson(ItemIdentifier instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'uid': instance.uid,
    };
