// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxInvitation extends ObjectBoxModel<Invitation> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late InvitationStatus status;
  late String householdId;
  late String inviterEmail;
  late String inviterUserId;
  late String recipientEmail;
  late String uniqueKey;
  ObjectBoxInvitation();
  ObjectBoxInvitation.from(Invitation original) {
    created = original.created;
    householdId = original.householdId;
    inviterEmail = original.inviterEmail;
    inviterUserId = original.inviterUserId;
    recipientEmail = original.recipientEmail;
    status = original.status;
    uniqueKey = original.uniqueKey;
    updated = original.updated;
  }
  Invitation convert() {
    return Invitation(
        created: created,
        householdId: householdId,
        inviterEmail: inviterEmail,
        inviterUserId: inviterUserId,
        recipientEmail: recipientEmail,
        status: status,
        uniqueKey: uniqueKey,
        updated: updated);
  }
}
