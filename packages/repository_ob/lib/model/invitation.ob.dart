// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxInvitation extends ObjectBoxModel<Invitation> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;
  late String uniqueKey;
  late String householdId;
  late String inviterEmail;
  late String inviterUserId;
  late String recipientEmail;
  late InvitationStatus status;
  ObjectBoxInvitation();
  ObjectBoxInvitation.from(Invitation original) {
    created = original.created;
    updated = original.updated;
    uniqueKey = original.uniqueKey;
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
        uniqueKey: uniqueKey,
        householdId: householdId,
        inviterEmail: inviterEmail,
        inviterUserId: inviterUserId,
        recipientEmail: recipientEmail,
        status: status);
  }
}
