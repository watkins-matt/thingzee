// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/location.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteLocationDatabase extends LocationDatabase
    with AppwriteSynchronizable<Location>, AppwriteDatabase<Location> {
  static const String TAG = 'AppwriteLocationDatabase';

  AppwriteLocationDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
  ) : super() {
    constructDatabase(TAG, database, databaseId, collectionId);
    constructSynchronizable(TAG, prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
  }

  @override
  List<String> get names {
    final uniqueLocations = values.map((location) => location.name).toSet();
    return uniqueLocations.toList();
  }

  @override
  Location? deserialize(Map<String, dynamic> json) => Location.fromJson(json);

  @override
  String getKey(Location location) => '${location.name}/${location.upc}';

  @override
  List<String> getSubPaths(String location) {
    location = normalizeLocation(location);
    final Set<String> subpaths = {};

    for (final loc in values) {
      var normalizedLocName = normalizeLocation(loc.name);

      if (normalizedLocName.startsWith(location) && normalizedLocName != location) {
        var remainingPath = normalizedLocName.substring(location.length);
        var nextSlashIndex = remainingPath.indexOf('/');

        if (nextSlashIndex != -1) {
          var subpath = remainingPath.substring(0, nextSlashIndex);

          // Remove trailing slash only if it exists
          if (subpath.endsWith('/')) {
            subpath = subpath.substring(0, subpath.length - 1);
          }

          subpaths.add(subpath);
        }

        // Handle top level directory
        else if (location == '/') {
          subpaths.add(remainingPath);
        }
      }
    }

    var result = subpaths.toList();
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  @override
  List<String> getUpcList(String location) {
    location = normalizeLocation(location);

    return values
        .where((loc) => normalizeLocation(loc.name) == location)
        .map((loc) => loc.upc)
        .toList();
  }

  @override
  DateTime? getUpdated(Location location) => location.updated;

  @override
  int itemCount(String location) => values.where((loc) => loc.name == location).length;

  @override
  Location merge(Location existingItem, Location newItem) => existingItem.merge(newItem);

  @override
  void remove(String location, String upc) {
    final key = getKey(Location(upc: upc, name: location));
    deleteById(key);
  }

  @override
  Map<String, dynamic> serialize(Location location) {
    assert(userId.isNotEmpty);

    var json = location.toJson();
    json['userId'] = userId;
    return json;
  }

  @override
  void store(String location, String upc) {
    location = normalizeLocation(location);
    var data = Location(upc: upc, name: location);
    final key = getKey(data);

    final existingLocation = get(key);

    if (existingLocation != null) {
      data = existingLocation.copyWith(updated: DateTime.now());
    }

    put(data);
  }
}
