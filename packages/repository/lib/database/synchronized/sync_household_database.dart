import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/household_member.dart';

class SynchronizedHouseholdDatabase extends HouseholdDatabase
    with SynchronizedDatabase<HouseholdMember> {
  static const String tag = 'SynchronizedHouseholdDatabase';

  SynchronizedHouseholdDatabase(
      HouseholdDatabase local, HouseholdDatabase remote, Preferences prefs)
      : super() {
    constructSyncDb(
      tag,
      local,
      remote,
      prefs,
    );
  }

  @override
  List<HouseholdMember> get admins => local.admins;

  @override
  DateTime get created => local.created;

  @override
  String get id => local.id;

  @override
  HouseholdDatabase get local => super.local as HouseholdDatabase;

  @override
  List<HouseholdMember> get members => local.members;

  @override
  HouseholdDatabase get remote => super.remote as HouseholdDatabase;

  @override
  void leave() {
    local.leave();
    remote.leave();
  }
}
