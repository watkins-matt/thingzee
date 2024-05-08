// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxHouseholdMember extends ObjectBoxModel<HouseholdMember> {
  @Id()
  int objectBoxId = 0;
  late bool isAdmin;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String email;
  late String householdId;
  late String name;
  late String userId;
  ObjectBoxHouseholdMember();
  ObjectBoxHouseholdMember.from(HouseholdMember original) {
    created = original.created;
    email = original.email;
    householdId = original.householdId;
    isAdmin = original.isAdmin;
    name = original.name;
    updated = original.updated;
    userId = original.userId;
  }
  HouseholdMember convert() {
    return HouseholdMember(
        created: created,
        email: email,
        householdId: householdId,
        isAdmin: isAdmin,
        name: name,
        updated: updated,
        userId: userId);
  }
}
