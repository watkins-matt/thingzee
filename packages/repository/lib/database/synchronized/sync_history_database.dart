import 'package:log/log.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';

class SynchronizedHistoryDatabase extends HistoryDatabase {
  final HistoryDatabase local;
  final HistoryDatabase remote;
  DateTime? lastSync;

  SynchronizedHistoryDatabase(this.local, this.remote) {
    synchronize();
  }

  @override
  List<History> all() {
    return local.all();
  }

  @override
  void delete(History history) {
    local.delete(history);
    remote.delete(history);
  }

  @override
  void deleteAll() {
    local.deleteAll();
    remote.deleteAll();
  }

  @override
  History? get(String upc) {
    return local.get(upc);
  }

  @override
  Map<String, History> map() {
    return local.map();
  }

  @override
  void put(History history) {
    local.put(history);
    remote.put(history);
  }

  void syncDifferences() {
    final since = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0);

    final remoteChanges = remote.getChanges(since);
    final localChanges = local.getChanges(since);

    final remoteMap = {for (var history in remoteChanges) history.upc: history};
    final localMap = {for (var history in localChanges) history.upc: history};
    int changes = 0;

    for (final remoteHistory in remoteChanges) {
      if (!localMap.containsKey(remoteHistory.upc)) {
        // If the local database does not contain the remote history, add it
        local.put(remoteHistory);
        changes++;
      }
      // The history exists in both databases, merge and add to both
      else {
        // If the remote history is the same as the local history, skip it
        if (remoteHistory.equalTo(localMap[remoteHistory.upc]!)) {
          continue;
        }

        final mergedHistory = localMap[remoteHistory.upc]!.merge(remoteHistory);
        local.put(mergedHistory);
        remote.put(mergedHistory);
        changes++;
      }
    }

    for (final localHistory in localChanges) {
      if (!remoteMap.containsKey(localHistory.upc)) {
        // If the remote database does not contain the local history, add it
        remote.put(localHistory);
        changes++;
      }
    }

    if (changes > 0) {
      Log.d('HistoryDatabase: Synchronized $changes items.');
    } else {
      Log.d('InventoryDatabase: No synchronization necessary, everything up to date.');
    }

    lastSync = DateTime.now();
    assert(local.all().length == remote.all().length);
  }

  void synchronize() {
    // Fetch all histories from both databases
    var localHistories = local.map();
    var remoteHistories = remote.map();

    // First go through all the remote histories, add the missing ones
    // to the database and merge the ones that exist in both
    for (final remoteHistory in remoteHistories.values) {
      if (!localHistories.containsKey(remoteHistory.upc)) {
        // If the local database does not contain the remote history, add it
        local.put(remoteHistory);
      }
      // The history exists in both databases
      else {
        // If the remote history is the same as the local history, skip it
        if (remoteHistory.equalTo(localHistories[remoteHistory.upc]!)) {
          continue;
        }

        final mergedHistory = localHistories[remoteHistory.upc]!.merge(remoteHistory);
        local.put(mergedHistory);
        remote.put(mergedHistory);
      }
    }

    // Now look for local histories that are missing in the remote, and
    // add them to the remote database
    for (final localHistory in localHistories.values) {
      if (!remoteHistories.containsKey(localHistory.upc)) {
        // If the remote database does not contain the local history, add it
        remote.put(localHistory);
      }
    }

    lastSync = DateTime.now();
    assert(local.all().length == remote.all().length);
  }
}
