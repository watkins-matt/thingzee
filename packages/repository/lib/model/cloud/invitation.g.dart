// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      inviterEmail: json['inviterEmail'] as String,
      inviterUserId: json['inviterUserId'] as String,
      recipientEmail: json['recipientEmail'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: $enumDecodeNullable(_$InvitationStatusEnumMap, json['status']) ??
          InvitationStatus.pending,
    );

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'householdId': instance.householdId,
      'inviterEmail': instance.inviterEmail,
      'inviterUserId': instance.inviterUserId,
      'recipientEmail': instance.recipientEmail,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': _$InvitationStatusEnumMap[instance.status]!,
    };

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.rejected: 'rejected',
};
