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
      timestamp: const DateTimeSerializer().fromJson(json['timestamp'] as int),
      status: json['status'] == null
          ? InvitationStatus.pending
          : const InvitationStatusSerializer().fromJson(json['status'] as int),
    );

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'householdId': instance.householdId,
      'inviterEmail': instance.inviterEmail,
      'inviterUserId': instance.inviterUserId,
      'recipientEmail': instance.recipientEmail,
      'timestamp': const DateTimeSerializer().toJson(instance.timestamp),
      'status': const InvitationStatusSerializer().toJson(instance.status),
    };
