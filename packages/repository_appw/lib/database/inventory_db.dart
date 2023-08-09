import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/inventory.dart';

class AppwriteInventoryDatabase extends InventoryDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
  DateTime? _lastRateLimitHit;
  DateTime? lastSync;
  String lastSyncKey = 'AppwriteInventoryDatabase.lastSync';
  final _inventory = <String, Inventory>{};
  final _taskQueue = <_QueueTask>[];
  final Databases _database;
  final Preferences prefs;
  final String collectionId;
  final String databaseId;
  String userId = '';

  AppwriteInventoryDatabase(
    this.prefs,
    this._database,
    this.databaseId,
    this.collectionId,
  ) {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  bool get online => _online;

  @override
  List<Inventory> all() => _inventory.values.toList();

  @override
  void delete(Inventory inv) {
    _inventory.remove(inv.upc);
    queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(inv.upc),
      );
    });
  }

  @override
  void deleteAll() {
    for (final inv in _inventory.values.toList()) {
      delete(inv);
    }
    _inventory.clear();
  }

  Inventory deserializeInventory(Map<String, dynamic> json) {
    return Inventory.fromJson(json);
  }

  @override
  Inventory? get(String upc) => _inventory[upc];

  @override
  List<Inventory> getAll(List<String> upcs) => _inventory.entries
      .where((entry) => upcs.contains(entry.key))
      .map((entry) => entry.value)
      .toList();

  @override
  List<Inventory> getChanges(DateTime since) {
    return _inventory.values
        .where((inventory) => inventory.lastUpdate != null && inventory.lastUpdate!.isAfter(since))
        .toList();
  }

  Future<void> handleConnectionChange(bool online, Session? session) async {
    if (online && session != null) {
      _online = true;
      userId = session.userId;
      await sync();
      scheduleMicrotask(_processQueue);
    } else {
      _online = false;
      userId = '';
    }
  }

  @override
  Map<String, Inventory> map() => Map.unmodifiable(_inventory);

  @override
  List<Inventory> outs() =>
      _inventory.values.where((inv) => inv.amount <= 0 && inv.restock).toList();

  @override
  void put(Inventory inv) {
    _inventory[inv.upc] = inv;

    queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(inv.upc),
            data: serializeInventory(inv));
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(inv.upc),
              data: serializeInventory(inv));
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(inv.upc),
              data: serializeInventory(inv));
        } else {
          Log.e('Failed to put inventory: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _inventory.remove(inv.upc);
          rethrow;
        }
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Map<String, dynamic> serializeInventory(Inventory inv) {
    var json = inv.toJson();
    json['userId'] = userId;
    json.remove('history');
    json.remove('units');

    return json;
  }

  Future<void> sync() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

    final timer = Log.timerStart();
    String? cursor;
    List<Inventory> allInventory = [];

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

        final items = _documentsToList(response);
        allInventory.addAll(items);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _inventory.clear();
      for (final inventory in allInventory) {
        _inventory[inventory.upc] = inventory;
      }
    } on AppwriteException catch (e) {
      Log.e('Failed to sync inventory: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: Inventory synced in \$seconds seconds.');
    _updateSyncTime();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('User ID is empty, cannot generate unique document ID');
    }

    return '$userId-$upc';
  }

  List<Inventory> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return deserializeInventory(doc.data);
    }).toList();
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
