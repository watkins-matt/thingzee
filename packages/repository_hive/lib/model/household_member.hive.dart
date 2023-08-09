import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/household_member.dart';

part 'household_member.hive.g.dart';
@HiveType(typeId: 5)
class HiveHouseholdMember extends HiveObject {
  @HiveField(0)
  late bool isAdmin;
  @HiveField(1)
  late DateTime timestamp;
  @HiveField(2)
  late String email;
  @HiveField(3)
  late String householdId;
  @HiveField(4)
  late String name;
  @HiveField(5)
  late String userId;
  HiveHouseholdMember();
  HiveHouseholdMember.from(HouseholdMember original) {
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
      userId: userId
    );
  }
}
