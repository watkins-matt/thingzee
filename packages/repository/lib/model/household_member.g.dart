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
      timestamp: _$JsonConverterFromJson<int, DateTime>(
          json['timestamp'], const DateTimeSerializer().fromJson),
      userId: json['userId'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
    );

Map<String, dynamic> _$HouseholdMemberToJson(HouseholdMember instance) =>
    <String, dynamic>{
      'isAdmin': instance.isAdmin,
      'timestamp': const DateTimeSerializer().toJson(instance.timestamp),
      'email': instance.email,
      'householdId': instance.householdId,
      'name': instance.name,
      'userId': instance.userId,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
