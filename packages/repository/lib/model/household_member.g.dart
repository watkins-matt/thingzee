// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdMember _$HouseholdMemberFromJson(Map<String, dynamic> json) =>
    HouseholdMember(
      email: json['email'] as String? ?? '',
      householdId: json['householdId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['updated'] as String),
      userId: json['userId'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
    );

Map<String, dynamic> _$HouseholdMemberToJson(HouseholdMember instance) =>
    <String, dynamic>{
      'created': instance.created?.toIso8601String(),
      'updated': instance.updated?.toIso8601String(),
      'isAdmin': instance.isAdmin,
      'email': instance.email,
      'householdId': instance.householdId,
      'name': instance.name,
      'userId': instance.userId,
    };
