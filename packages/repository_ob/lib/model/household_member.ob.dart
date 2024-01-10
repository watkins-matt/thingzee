import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/household_member.dart';

@Entity()
class ObjectBoxHouseholdMember {
  late DateTime? created;
  late DateTime? updated;
  late bool isAdmin;
  late String email;
  late String householdId;
  late String name;
  late String userId;
  @Id()
  int objectBoxId = 0;
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
  HouseholdMember toHouseholdMember() {
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
