import 'package:log/log.dart';
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/location.dart';

class SynchronizedLocationDatabase extends LocationDatabase {
  final LocationDatabase local;
  final LocationDatabase remote;
  final Preferences prefs;
  final String lastSyncKey = 'SynchronizedLocationDatabase.lastSync';
  DateTime? lastSync;

  SynchronizedLocationDatabase(this.local, this.remote, this.prefs);

  @override
  List<String> get names => local.names;

  @override
  List<Location> all() {
    return local.all();
  }

  @override
  List<Location> getChanges(DateTime since) {
    return local.getChanges(since);
  }

  @override
  List<Location> getContents(String location) {
    syncDifferences();
    return local.getContents(location);
  }

  @override
  List<String> getUpcList(String location) {
    syncDifferences();
    return local.getUpcList(location);
  }

  @override
  int itemCount(String location) {
    syncDifferences();
    return local.itemCount(location);
  }

  @override
  Map<String, Location> map() {
    return local.map();
  }

  @override
  void remove(String location, String upc) {
    local.remove(location, upc);
    remote.remove(location, upc);
  }

  @override
  void store(String location, String upc) {
    local.store(location, upc);
    remote.store(location, upc);
  }

  void syncDifferences() {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }

    if (lastSync == null) {
      Log.d('LocationDatabase: No last sync time found, synchronizing everything.');
      synchronize();
      return;
    }

    Log.d('LocationDatabase: Synchronizing differences...');

    final remoteChanges = remote.getChanges(lastSync!);
    final localChanges = local.getChanges(lastSync!);

    final remoteMap = {
      for (final location in remoteChanges) '${location.location}-${location.upc}': location
    };
    final localMap = {
      for (final location in localChanges) '${location.location}-${location.upc}': location
    };
    int changes = 0;

    for (final remoteLocation in remoteChanges) {
      final key = '${remoteLocation.location}-${remoteLocation.upc}';
      if (!localMap.containsKey(key)) {
        local.store(remoteLocation.location, remoteLocation.upc);
        changes++;
        Log.d(
            'Added remote location "${remoteLocation.location}" with UPC "${remoteLocation.upc}" to local database.');
      } else {
        final mergedLocation = localMap[key]!.merge(remoteLocation);
        local.store(mergedLocation.location, mergedLocation.upc);
        remote.store(mergedLocation.location, mergedLocation.upc);
        changes++;
        Log.d(
            'Merged remote location "${remoteLocation.location}" with UPC "${remoteLocation.upc}" with local database.');
      }
    }

    for (final localLocation in localChanges) {
      final key = '${localLocation.location}-${localLocation.upc}';
      if (!remoteMap.containsKey(key)) {
        remote.store(localLocation.location, localLocation.upc);
        changes++;
        Log.d(
            'Added local location "${localLocation.location}" with UPC "${localLocation.upc}" to remote database.');
      }
    }

    if (changes > 0) {
      Log.d('LocationDatabase: Synchronized $changes locations.');
    } else {
      Log.d('LocationDatabase: No synchronization necessary, everything up to date.');
    }

    _updateSyncTime();
  }

  void synchronize() {
    final localMap = local.map();
    final remoteMap = remote.map();

    // First, go through all the remote locations, add the missing ones
    // to the database, and merge the ones that exist in both
    for (final key in remoteMap.keys) {
      final remoteLocation = remoteMap[key]!;
      if (!localMap.containsKey(key)) {
        // If the local database does not contain the remote location, add it
        local.store(remoteLocation.location, remoteLocation.upc);
      } else {
        final localLocation = localMap[key]!;
        // The location exists in both databases, check if they are equal
        if (!remoteLocation.equalTo(localLocation)) {
          // If the locations are not equal, merge them
          final mergedLocation = localLocation.merge(remoteLocation);
          local.store(mergedLocation.location, mergedLocation.upc);
          remote.store(mergedLocation.location, mergedLocation.upc);
        }
      }
    }

    // Now, look for local locations that are missing in the remote, and add them to the remote database
    for (final key in localMap.keys) {
      if (!remoteMap.containsKey(key)) {
        final localLocation = localMap[key]!;
        remote.store(
            localLocation.location, localLocation.upc); // Add appropriate quantity if needed
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
