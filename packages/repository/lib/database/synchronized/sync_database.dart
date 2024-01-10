import 'package:log/log.dart';
import 'package:repository/database/database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/abstract/model.dart';

abstract class SynchronizedDatabase<T extends Model> implements Database<T> {
  final Database<T> local;
  final Database<T> remote;
  final Preferences prefs;
  final String lastSyncKey;
  DateTime? lastSync;

  SynchronizedDatabase(this.local, this.remote, this.prefs, this.lastSyncKey);

  @override
  List<T> all() => local.all();

  @override
  void delete(T record) {
    local.delete(record);
    remote.delete(record);
  }

  @override
  void deleteAll() {
    local.deleteAll();
    remote.deleteAll();
  }

  @override
  T? get(String id) => local.get(id);

  @override
  Map<String, T> map() {
    return local.map();
  }

  @override
  void put(T record) {
    local.put(record);
    remote.put(record);
  }

  void syncDifferences() {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    lastSync = lastSyncMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis) : null;

    if (lastSync == null) {
      Log.d('${T.runtimeType}Database: No last sync time found, synchronizing everything.');
      synchronize();
      return;
    }

    Log.d('${T.runtimeType}Database: Synchronizing differences...');
    var remoteChanges = remote.getChanges(lastSync!);
    var localChanges = local.getChanges(lastSync!);
    var remoteMap = {for (final r in remoteChanges) getKey(r): r};
    var localMap = {for (final l in localChanges) getKey(l): l};
    int changes = 0;

    for (final remoteRecord in remoteChanges) {
      var id = getKey(remoteRecord);
      if (!localMap.containsKey(id)) {
        local.put(remoteRecord);
        changes++;
      } else if (!isEqual(remoteRecord, localMap[id] as T)) {
        var merged = merge(localMap[id] as T, remoteRecord);
        local.put(merged);
        remote.put(merged);
        changes++;
      }
    }

    for (final localRecord in localChanges) {
      var id = getKey(localRecord);
      if (!remoteMap.containsKey(id)) {
        remote.put(localRecord);
        changes++;
      }
    }

    if (local.all().length != remote.all().length) {
      Log.w(
          '${T.runtimeType}Database: Local and remote databases are out of sync, performing full synchronization.');
      synchronize();
      return;
    }

    if (changes > 0) {
      Log.d('${T.runtimeType}Database: Synchronized $changes items.');
    } else {
      Log.d('${T.runtimeType}Database: No synchronization necessary, everything up to date.');
    }

    _updateSyncTime();
  }

  void synchronize() {
    var localRecords = local.map();
    var remoteRecords = remote.map();

    for (final remoteRecord in remoteRecords.values) {
      var id = getKey(remoteRecord);
      if (!localRecords.containsKey(id)) {
        local.put(remoteRecord);
      } else if (!isEqual(remoteRecord, localRecords[id] as T)) {
        var merged = merge(localRecords[id] as T, remoteRecord);
        local.put(merged);
        remote.put(merged);
      }
    }

    for (final localRecord in localRecords.values) {
      var id = getKey(localRecord);
      if (!remoteRecords.containsKey(id)) {
        remote.put(localRecord);
      }
    }

    _updateSyncTime();
    assert(local.all().length == remote.all().length);
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
