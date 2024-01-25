// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxInvitation extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
  late String id;
  late String householdId;
  late String inviterEmail;
  late String inviterUserId;
  late String recipientEmail;
  late InvitationStatus status;
  ObjectBoxInvitation();
  ObjectBoxInvitation.from(Invitation original) {
    created = original.created;
    updated = original.updated;
    id = original.id;
    householdId = original.householdId;
    inviterEmail = original.inviterEmail;
    inviterUserId = original.inviterUserId;
    recipientEmail = original.recipientEmail;
    status = original.status;
  }
  Invitation toInvitation() {
    return Invitation(
        created: created,
        updated: updated,
        id: id,
        householdId: householdId,
        inviterEmail: inviterEmail,
        inviterUserId: inviterUserId,
        recipientEmail: recipientEmail,
        status: status);
  }
}
