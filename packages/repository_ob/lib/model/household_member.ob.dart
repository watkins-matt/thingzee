import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/household_member.dart';

@Entity()
class ObjectBoxHouseholdMember {
  late bool isAdmin;
  late DateTime timestamp;
  late String email;
  late String householdId;
  late String name;
  late String userId;
  @Id()
  int objectBoxId = 0;
  ObjectBoxHouseholdMember();
  ObjectBoxHouseholdMember.from(HouseholdMember original) {
    isAdmin = original.isAdmin;
    timestamp = original.timestamp;
    email = original.email;
    householdId = original.householdId;
    name = original.name;
    userId = original.userId;
  }
  HouseholdMember toHouseholdMember() {
    return HouseholdMember(
        isAdmin: isAdmin,
        timestamp: timestamp,
        email: email,
        householdId: householdId,
        name: name,
        userId: userId);
  }
}
