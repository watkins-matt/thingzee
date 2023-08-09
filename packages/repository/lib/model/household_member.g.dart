// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdMember _$HouseholdMemberFromJson(Map<String, dynamic> json) => HouseholdMember(
      email: json['email'] as String,
      householdId: json['householdId'] as String,
      name: json['name'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      userId: json['userId'] as String?,
      timestamp: json['timestamp'] == null ? null : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$HouseholdMemberToJson(HouseholdMember instance) => <String, dynamic>{
      'isAdmin': instance.isAdmin,
      'timestamp': instance.timestamp.toIso8601String(),
      'email': instance.email,
      'householdId': instance.householdId,
      'name': instance.name,
      'userId': instance.userId,
    };
