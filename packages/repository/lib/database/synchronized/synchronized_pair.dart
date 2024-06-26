import 'package:log/log.dart';
import 'package:repository/database/database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/abstract/model.dart';

class SynchronizedPair<T extends Model> {
  final Database<T> local;
  final Database<T> remote;
  final Preferences prefs;
  String lastSyncKey;
  DateTime? lastSync;
  final String tag;

  SynchronizedPair(this.tag, this.local, this.remote, this.prefs)
      : lastSyncKey = 'Synchronized$tag.lastSync';

  void synchronize() {
    // Fetch the last synchronization time
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    lastSync = lastSyncMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis) : null;

    // Synchronize everything if no last sync time is found
    if (lastSync == null) {
      Log.d('$tag: No last sync time found, synchronizing everything.');
      synchronizeAll();
      return;
    }

    var remoteChanges = remote.getChanges(lastSync!);
    var localChanges = local.getChanges(lastSync!);
    var remoteMap = {for (final r in remoteChanges) r.uniqueKey: r};
    var localMap = {for (final l in localChanges) l.uniqueKey: l};
    int changes = 0;

    // Synchronize changes from remote database
    for (final remoteRecord in remoteChanges) {
      var id = remoteRecord.uniqueKey;
      // Add remote records not in the local database
      if (!localMap.containsKey(id)) {
        local.put(remoteRecord);
        changes++;
      }
      // Merge records that exist in both databases but are not equal
      else if (!remoteRecord.equalTo(localMap[id] as T)) {
        var merged = (localMap[id] as T).merge(remoteRecord);
        local.put(merged);
        remote.put(merged);
        changes++;
      }
    }

    // Synchronize changes from local database to remote
    for (final localRecord in localChanges) {
      var id = localRecord.uniqueKey;
      // Add local records not in the remote database
      if (!remoteMap.containsKey(id)) {
        remote.put(localRecord);
        changes++;
      }
    }

    // Perform a full synchronization if the databases are out of sync
    if (local.all().length != remote.all().length) {
      Log.w('$tag: Local and remote databases are out of sync, performing full synchronization.');
      synchronizeAll();
      return;
    }

    // Log the number of synchronized items
    if (changes > 0) {
      Log.d('$tag: Synchronized $changes items.');
    } else {
      Log.d('$tag: No synchronization necessary, everything up to date.');
    }

    // Update the last synchronization time
    _updateSyncTime();
  }

  void synchronizeAll() {
    // Fetch all records from both local and remote databases
    var localRecords = local.map();
    var remoteRecords = remote.map();

    // Go through all the remote records, add the missing ones
    // to the local database, and merge the ones that exist in both
    for (final remoteRecord in remoteRecords.values) {
      var id = remoteRecord.uniqueKey;
      if (!localRecords.containsKey(id)) {
        // If the local database does not contain the remote record, add it
        local.put(remoteRecord);
      } else {
        // The record exists in both databases
        if (!remoteRecord.equalTo(localRecords[id] as T)) {
          // If the remote record is different from the local record, merge them
          var merged = (localRecords[id] as T).merge(remoteRecord);

          // Update both local and remote databases with the merged record
          local.put(merged);
          remote.put(merged);
        }
      }
    }

    // Now look for local records that are missing in the remote database,
    // and add them to the remote database
    for (final localRecord in localRecords.values) {
      var id = localRecord.uniqueKey;
      if (!remoteRecords.containsKey(id)) {
        // If the remote database does not contain the local record, add it
        remote.put(localRecord);
      }
    }

    // Update the last synchronization time
    _updateSyncTime();

    // Assert that the number of records in both databases is equal after synchronization
    assert(local.all().length == remote.all().length);
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
