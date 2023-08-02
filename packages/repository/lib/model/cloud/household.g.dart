// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Household _$HouseholdFromJson(Map<String, dynamic> json) => Household(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userIds:
          (json['userIds'] as List<dynamic>).map((e) => e as String).toList(),
      adminIds:
          (json['adminIds'] as List<dynamic>).map((e) => e as String).toList(),
      names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$HouseholdToJson(Household instance) => <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'userIds': instance.userIds,
      'adminIds': instance.adminIds,
      'names': instance.names,
    };
