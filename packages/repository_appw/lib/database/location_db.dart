import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/location.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';
import 'package:uuid/uuid.dart';

class AppwriteLocationDatabase extends LocationDatabase {
  bool _online = false;
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  DateTime? lastSync;
  final Databases _database;
  final String collectionId;
  final Preferences prefs;
  final String databaseId;
  final List<Location> _locations = [];
  String lastSyncKey = 'AppwriteLocationDatabase.lastSync';
  String userId = '';

  AppwriteLocationDatabase(this.prefs, this._database, this.databaseId, this.collectionId) {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  @override
  List<String> get names {
    final uniqueLocations = _locations.map((location) => location.name).toSet();
    return uniqueLocations.toList();
  }

  @override
  List<Location> all() => List.unmodifiable(_locations);

  @override
  List<Location> getChanges(DateTime since) {
    return _locations
        .where((location) => location.updated != null && location.updated!.isAfter(since))
        .toList();
  }

  @override
  List<String> getSubPaths(String location) {
    location = normalizeLocation(location);
    final Set<String> subpaths = {};

    for (final loc in _locations) {
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

    return _locations
        .where((loc) => normalizeLocation(loc.name) == location)
        .map((loc) => loc.upc)
        .toList();
  }

  Future<void> handleConnectionChange(bool online, Session? session) async {
    if (online && session != null) {
      _online = true;
      userId = session.userId;

      await taskQueue.runUntilComplete();
      await sync();
    } else {
      _online = false;
      userId = '';
    }
  }

  @override
  int itemCount(String location) {
    return _locations.where((loc) => loc.name == location).length;
  }

  @override
  Map<String, Location> map() {
    final allLocations = all();
    final map = {for (final location in allLocations) '${location.name}-${location.upc}': location};

    return map;
  }

  @override
  void remove(String location, String upc) {
    taskQueue.queueTask(() async {
      List<String> query = [Query.equal('name', location), Query.equal('upc', upc)];
      final response = await _database.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: query,
      );

      for (final document in response.documents) {
        await _database.deleteDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: document.$id,
        );
      }

      _locations.removeWhere((loc) => loc.name == location && loc.upc == upc);
    });
  }

  Map<String, dynamic> serializeLocation(Location location) {
    assert(userId.isNotEmpty);

    var json = location.toJson();
    json['userId'] = userId;
    return json;
  }

  @override
  void store(String location, String upc) {
    location = normalizeLocation(location);

    taskQueue.queueTask(() async {
      final query = [Query.equal('name', location), Query.equal('upc', upc)];
      final response = await _database.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: query,
      );

      final locationData =
          Location(name: location, upc: upc, created: DateTime.now(), updated: DateTime.now());

      if (response.documents.isEmpty) {
        await _database.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: Uuid().v4(),
            data: serializeLocation(locationData));
      } else {
        for (final document in response.documents) {
          await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: document.$id,
            data: serializeLocation(locationData),
          );
        }
      }

      _locations.add(locationData);
    });
  }

  Future<void> sync() async {
    if (!_online) return;

    final timer = Log.timerStart();
    String? cursor;
    List<Location> allLocations = [];

    try {
      DocumentList response;

      do {
        List<String> queries = [Query.limit(100)];

        if (cursor != null) {
          queries.add(Query.cursorAfter(cursor));
        }

        response = await _database.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: queries,
        );

        final locations = _documentsToLocations(response);
        allLocations.addAll(locations);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _locations.clear();
      _locations.addAll(allLocations);
    } on AppwriteException catch (e) {
      Log.e('Failed to sync locations: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: Locations synced in \$seconds seconds.');
    _updateSyncTime();
  }

  List<Location> _documentsToLocations(DocumentList documentList) {
    return documentList.documents
        .map((document) {
          try {
            return Location.fromJson(document.data);
          } catch (e) {
            Log.w('Failed to deserialize location for upc ${document.data["upc"]}. Error: $e');
            return null;
          }
        })
        .where((location) => location != null)
        .cast<Location>()
        .toList();
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
