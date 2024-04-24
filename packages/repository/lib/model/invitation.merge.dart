// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

Invitation _$mergeInvitation(Invitation first, Invitation second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Invitation(
    uniqueKey: newer.uniqueKey.isNotEmpty ? newer.uniqueKey : first.uniqueKey,
    householdId: newer.householdId.isNotEmpty ? newer.householdId : first.householdId,
    inviterEmail: newer.inviterEmail.isNotEmpty ? newer.inviterEmail : first.inviterEmail,
    inviterUserId: newer.inviterUserId.isNotEmpty ? newer.inviterUserId : first.inviterUserId,
    recipientEmail: newer.recipientEmail.isNotEmpty ? newer.recipientEmail : first.recipientEmail,
    status: newer.status,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
