import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

class AppwriteInventoryDatabase extends InventoryDatabase {
  bool _online = false;
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();

  DateTime? lastSync;
  String lastSyncKey = 'AppwriteInventoryDatabase.lastSync';
  final _inventory = <String, Inventory>{};
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
    taskQueue.queueTask(() async {
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

      await taskQueue.runUntilComplete();
      await sync();
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

    taskQueue.queueTask(() async {
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
          Log.e('AppwriteInventoryDB: Failed to put inventory ${inv.upc}: [AppwriteException]',
              e.message);
          rethrow;
        }
      }
    });
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
      throw Exception('User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, upc);
  }

  List<Inventory> _documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            return deserializeInventory(doc.data);
          } catch (e) {
            Log.e('AppwriteInventoryDB: Error deserializing inventory:', e.toString());
            return null;
          }
        })
        .where((item) => item != null)
        .cast<Inventory>()
        .toList();
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
