import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/synchronized/sync_database.dart';
import 'package:repository/model/household_member.dart';

class SynchronizedHouseholdDatabase extends HouseholdDatabase
    with SynchronizedDatabase<HouseholdMember, HouseholdDatabase> {
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
  void leave() {
    local.leave();
    remote.leave();
  }
}
