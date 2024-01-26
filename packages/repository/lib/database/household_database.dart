import 'package:repository/database/database.dart';
import 'package:repository/model/household_member.dart';

abstract class HouseholdDatabase implements Database<HouseholdMember> {
  List<HouseholdMember> get admins;
  DateTime get created;
  String get id;
  void leave();
}
