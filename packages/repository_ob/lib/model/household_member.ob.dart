// ignore_for_file: annotate_overrides

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxHouseholdMember extends ObjectBoxModel<HouseholdMember> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late bool isAdmin;
  late String email;
  late String householdId;
  late String name;
  late String userId;
  ObjectBoxHouseholdMember();
  ObjectBoxHouseholdMember.from(HouseholdMember original) {
    created = original.created;
    updated = original.updated;
    isAdmin = original.isAdmin;
    email = original.email;
    householdId = original.householdId;
    name = original.name;
    userId = original.userId;
  }
  HouseholdMember convert() {
    return HouseholdMember(
        created: created,
        updated: updated,
        isAdmin: isAdmin,
        email: email,
        householdId: householdId,
        name: name,
        userId: userId);
  }
}
