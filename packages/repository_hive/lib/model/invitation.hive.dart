// ignore_for_file: annotate_overrides

import 'package:hive/hive.dart';
import 'package:repository/model/invitation.dart';

part 'invitation.hive.g.dart';

@HiveType(typeId: 0)
class HiveInvitation extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String id;
  @HiveField(3)
  late String householdId;
  @HiveField(4)
  late String inviterEmail;
  @HiveField(5)
  late String inviterUserId;
  @HiveField(6)
  late String recipientEmail;
  @HiveField(7)
  late InvitationStatus status;
  HiveInvitation();
  HiveInvitation.from(Invitation original) {
    created = original.created;
    updated = original.updated;
    id = original.uniqueKey;
    householdId = original.householdId;
    inviterEmail = original.inviterEmail;
    inviterUserId = original.inviterUserId;
    recipientEmail = original.recipientEmail;
    status = original.status;
  }
  Invitation convert() {
    return Invitation(
        created: created,
        updated: updated,
        uniqueKey: id,
        householdId: householdId,
        inviterEmail: inviterEmail,
        inviterUserId: inviterUserId,
        recipientEmail: recipientEmail,
        status: status);
  }
}
