import 'package:repository/model/household_member.dart';

abstract class HouseholdDatabase {
  List<HouseholdMember> get admins;
  DateTime get created;
  String get id;
  List<HouseholdMember> get members;

  void addMember(String name, String email, {String? id, bool isAdmin = false});
  void leave();
}
