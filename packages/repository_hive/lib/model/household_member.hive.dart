// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/household_member.dart';

part 'household_member.hive.g.dart';

@HiveType(typeId: 0)
class HiveHouseholdMember extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late bool isAdmin;
  @HiveField(3)
  late String email;
  @HiveField(4)
  late String householdId;
  @HiveField(5)
  late String name;
  @HiveField(6)
  late String userId;
  HiveHouseholdMember();
  HiveHouseholdMember.from(HouseholdMember original) {
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
