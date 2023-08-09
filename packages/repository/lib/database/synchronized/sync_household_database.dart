import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:uuid/uuid.dart';

class SynchronizedHouseholdDatabase extends HouseholdDatabase {
  final HouseholdDatabase local;
  final HouseholdDatabase remote;
  final Preferences prefs;
  final String lastSyncKey = 'SynchronizedHouseholdDatabase.lastSync';
  DateTime? lastSync;

  SynchronizedHouseholdDatabase(this.local, this.remote, this.prefs);

  @override
  List<HouseholdMember> get admins => local.admins;

  @override
  DateTime get created => local.created;

  @override
  String get id => local.id;

  @override
  List<HouseholdMember> get members => local.members;

  @override
  void addMember(String name, String email, {String? id, bool isAdmin = false}) {
    // Ensure we use the same uuid for both databases
    id ??= const Uuid().v4();

    local.addMember(name, email, id: id, isAdmin: isAdmin);
    remote.addMember(name, email, id: id, isAdmin: isAdmin);
  }

  @override
  List<HouseholdMember> getChanges(DateTime since) {
    return local.getChanges(since);
  }

  @override
  void leave() {
    local.leave();
    remote.leave();
  }

  void syncDifferences() {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }

    if (lastSync == null) {
      Log.d('HouseholdDatabase: No last sync time found, synchronizing everything.');
      synchronize();
      return;
    }

    Log.d('HouseholdDatabase: Synchronizing differences...');

    final remoteChanges = remote.getChanges(lastSync!);
    final localChanges = local.getChanges(lastSync!);

    final remoteMap = {for (var member in remoteChanges) member.email: member};
    final localMap = {for (var member in localChanges) member.email: member};
    int changes = 0;

    for (final remoteMember in remoteChanges) {
      if (!localMap.containsKey(remoteMember.email)) {
        // If the local database does not contain the remote member, add it
        local.addMember(remoteMember.name, remoteMember.email,
            id: remoteMember.userId, isAdmin: remoteMember.isAdmin);
        changes++;
        Log.d('Added remote member "${remoteMember.name}" to local database.');
      }
      // If the members are equal, skip
      else if (remoteMember == localMap[remoteMember.email]!) {
        continue;
      }
    }

    for (final localMember in localChanges) {
      if (!remoteMap.containsKey(localMember.email)) {
        // If the remote database does not contain the local member, add it
        remote.addMember(localMember.name, localMember.email,
            id: localMember.userId, isAdmin: localMember.isAdmin);
        changes++;
        Log.d('Added local member "${localMember.name}" to remote database.');
      }
    }

    // If the databases are out of sync, perform a full synchronization
    if (local.members.length != remote.members.length) {
      Log.w(
          'HouseholdDatabase: Local and remote databases are out of sync, performing full synchronization.');
      synchronize();
      return;
    }

    if (changes > 0) {
      Log.d('HouseholdDatabase: Synchronized $changes members.');
    } else {
      Log.d('HouseholdDatabase: No synchronization necessary, everything up to date.');
    }

    _updateSyncTime();
  }

  void synchronize() {
    // Fetch all members from both databases
    var localMembers = local.members;
    var remoteMembers = remote.members;

    // Convert to maps for easier lookup using email as the key
    var localMap = {for (var member in localMembers) member.email: member};
    var remoteMap = {for (var member in remoteMembers) member.email: member};

    // Go through all the local members and add the missing ones to the remote
    for (final localMember in localMembers) {
      if (!remoteMap.containsKey(localMember.email)) {
        remote.addMember(localMember.name, localMember.email,
            id: localMember.userId, isAdmin: localMember.isAdmin);
      }
    }

    // Go through all the remote members and add the missing ones to the local
    for (final remoteMember in remoteMembers) {
      if (!localMap.containsKey(remoteMember.email)) {
        local.addMember(remoteMember.name, remoteMember.email,
            id: remoteMember.userId, isAdmin: remoteMember.isAdmin);
      }
    }

    _updateSyncTime();
    assert(local.members.length == remote.members.length);
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
