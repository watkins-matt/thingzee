// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/location.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteLocationDatabase extends LocationDatabase
    with AppwriteSynchronizable<Location>, AppwriteDatabase<Location> {
  static const String tag = 'AppwriteLocationDatabase';

  // Current household ID, defaults to user ID if not in a household
  String _householdId = '';

  AppwriteLocationDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
  ) : super() {
    constructDatabase(tag, database, databaseId, collectionId);
    constructSynchronizable(tag, prefs, onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });

    // Initialize the household ID with the user ID
    _householdId = userId;
  }

  /// Updates the household ID when a user joins a new household
  void updateHouseholdId(String householdId) {
    _householdId = householdId;
  }

  @override
  List<String> get names {
    final uniqueLocations = values.map((location) => location.name).toSet();
    return uniqueLocations.toList();
  }

  @override
  Location? deserialize(Map<String, dynamic> json) => Location.fromJson(json);

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
  int itemCount(String location) => values.where((loc) => loc.name == location).length;

  @override
  void remove(String location, String upc) {
    final key = Location(upc: upc, name: location).uniqueKey;
    deleteById(key);
  }

  @override
  Map<String, dynamic> serialize(Location location) {
    assert(userId.isNotEmpty);

    var json = location.toJson();
    json['userId'] = userId;
    json['householdId'] = _householdId;
    return json;
  }

  @override
  void store(String location, String upc) {
    location = normalizeLocation(location);
    var data = Location(upc: upc, name: location);
    final key = data.uniqueKey;

    final existingLocation = get(key);

    if (existingLocation != null) {
      data = existingLocation.copyWith(updated: DateTime.now());
    }

    put(data);
  }

  /// Overrides the default getDocuments method to include household filtering
  @override
  Future<appwrite_models.DocumentList> getDocuments(List<String> queries) async {
    // Ensure we fetch all documents for the current household, not just user's
    final householdQueries = [
      ...queries,
      Query.equal('householdId', _householdId),
    ];

    // Call the parent method to handle the actual database access
    return await super.getDocuments(householdQueries);
  }

  /// Overrides the default getModifiedDocuments to include household data
  @override
  Future<appwrite_models.DocumentList> getModifiedDocuments(DateTime? lastSyncTime) async {
    // Get documents that have been updated since the last sync
    final timeQuery = Query.greaterThan(
        'updated', lastSyncTime?.millisecondsSinceEpoch ?? 0);

    // Use multiple queries to get documents that:
    // 1. Have been updated since last sync AND
    // 2. Belong to the current household
    final queries = [
      timeQuery,
      Query.equal('householdId', _householdId),
    ];

    // Use the general getDocuments method to avoid direct database access
    return await getDocuments(queries);
  }
}
