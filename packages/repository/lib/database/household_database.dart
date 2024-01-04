import 'package:repository/model/household_member.dart';

abstract class HouseholdDatabase {
  List<HouseholdMember> get admins;
  DateTime get created;
  String get id;
  List<HouseholdMember> get members;
  List<HouseholdMember> getChanges(DateTime since);
  void leave();
  void put(HouseholdMember member);
}
