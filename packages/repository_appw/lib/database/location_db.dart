import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/location_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/location.dart';
import 'package:uuid/uuid.dart';

class AppwriteLocationDatabase extends LocationDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
  final _taskQueue = <_QueueTask>[];
  DateTime? _lastRateLimitHit;
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

      scheduleMicrotask(_processQueue);
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

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  @override
  void remove(String location, String upc) {
    queueTask(() async {
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

    queueTask(() async {
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

  Future<void> _processQueue() async {
    if (_processingQueue || !_online) {
      return;
    }
    _processingQueue = true;

    try {
      while (_taskQueue.isNotEmpty) {
        // We hit a rate limit, pause the queue until the rate limit is over
        if (_lastRateLimitHit != null) {
          final difference = DateTime.now().difference(_lastRateLimitHit!);
          if (difference < Duration(minutes: 1)) {
            final timeToWait = Duration(minutes: 1) - difference;
            await Future.delayed(timeToWait);
            _lastRateLimitHit = null;
          }
        }

        _QueueTask task = _taskQueue.removeAt(0);

        if (task.retries >= maxRetries) {
          Log.e('Failed to execute task after $maxRetries attempts.');
          continue;
        }

        try {
          await task.operation();
        } on AppwriteException catch (e) {
          // Pause queue processing if we hit a rate limit
          if (e.code == 429) {
            Log.e('Rate limit hit. Pausing queue processing.');
            _lastRateLimitHit = DateTime.now();
            _taskQueue.add(task);
          } else if (e.code != 404 && e.code != 409) {
            Log.e(
                'Failed to execute task: [AppwriteException] ${e.message}. Retry attempt ${task.retries + 1}');
            task.retries += 1;
            _taskQueue.add(task);
          }
        }
      }
    } finally {
      _processingQueue = false;
    }
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
