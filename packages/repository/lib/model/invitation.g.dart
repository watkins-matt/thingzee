// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
      id: json['id'] as String? ?? '',
      householdId: json['householdId'] as String? ?? '',
      inviterEmail: json['inviterEmail'] as String? ?? '',
      inviterUserId: json['inviterUserId'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String? ?? '',
      status: json['status'] == null
          ? InvitationStatus.pending
          : const InvitationStatusSerializer().fromJson(json['status'] as int),
      created: _$JsonConverterFromJson<int, DateTime?>(
          json['created'], const NullableDateTimeSerializer().fromJson),
      updated: _$JsonConverterFromJson<int, DateTime?>(
          json['updated'], const NullableDateTimeSerializer().fromJson),
    );

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'created': const NullableDateTimeSerializer().toJson(instance.created),
      'updated': const NullableDateTimeSerializer().toJson(instance.updated),
      'id': instance.id,
      'householdId': instance.householdId,
      'inviterEmail': instance.inviterEmail,
      'inviterUserId': instance.inviterUserId,
      'recipientEmail': instance.recipientEmail,
      'status': const InvitationStatusSerializer().toJson(instance.status),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);
