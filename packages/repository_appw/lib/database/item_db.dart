import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:collection/collection.dart';
import 'package:log/log.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

class AppwriteItemDatabase extends ItemDatabase {
  static const String lastSyncKey = 'AppwriteItemDatabase.lastSync';
  bool _online = false;
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  DateTime? lastSync;

  final _items = <String, Item>{};
  final Databases _database;
  final Preferences prefs;
  final String collectionId;
  final String databaseId;
  String userId = '';

  AppwriteItemDatabase(
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
  List<Item> all() => _items.values.toList();

  @override
  void delete(Item item) {
    _items.remove(item.upc);
    taskQueue.queueTask(() async => await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(item.upc)));
  }

  @override
  void deleteAll() {
    for (final item in _items.values.toList()) {
      delete(item);
    }
    _items.clear();
  }

  @override
  List<Item> filter(Filter filter) {
    return _items.values
        .where((item) =>
            (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
        .toList();
  }

  @override
  Item? get(String upc) {
    return _items[upc];
  }

  @override
  List<Item> getAll(List<String> upcs) {
    return upcs.map((upc) => _items[upc]).whereNotNull().toList();
  }

  @override
  List<Item> getChanges(DateTime since) {
    return _items.values
        .where((item) => item.lastUpdate != null && item.lastUpdate!.isAfter(since))
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
  Map<String, Item> map() {
    return Map.unmodifiable(_items);
  }

  @override
  void put(Item item) {
    _items[item.upc] = item;

    taskQueue.queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(item.upc),
            data: serializeItem(item));
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: serializeItem(item));
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: serializeItem(item));
        } else {
          Log.e('Failed to put item ${item.upc}: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _items.remove(item.upc);
          rethrow;
        }
      }
    });
  }

  @override
  List<Item> search(String string) {
    return _items.values.where((item) => item.name.contains(string)).toList();
  }

  Map<String, dynamic> serializeItem(Item item) {
    var json = item.toJson();
    json['userId'] = userId;
    return json;
  }

  Future<void> sync() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

    final timer = Log.timerStart();
    String? cursor;
    List<Item> allItems = [];

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
        allItems.addAll(items);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _items.clear();
      for (final item in allItems) {
        _items[item.upc] = item;
      }
    } on AppwriteException catch (e) {
      Log.e(e);
    }

    Log.timerEnd(timer, 'AppwriteItemDB: Items synced in \$seconds seconds.');
    _updateSyncTime();
  }

  Future<void> syncModified() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

    final timer = Log.timerStart();

    try {
      DocumentList response = await _database.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: [Query.greaterThan('lastUpdate', lastSync?.millisecondsSinceEpoch ?? 0)]);
      var changedItems = _documentsToList(response);
      for (final item in changedItems) {
        final existingItem = _items[item.upc];
        final mergedItem = existingItem?.merge(item) ?? item;
        _items[item.upc] = mergedItem;
      }
    } on AppwriteException catch (e) {
      Log.e('AppwriteItemDB: Error while syncing modifications: $e');
    }

    Log.timerEnd(timer, 'AppwriteItemDB: Modified item sync completed in \$seconds seconds.');
    _updateSyncTime();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('AppwriteItemDB: User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, upc);
  }

  List<Item> _documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            return Item.fromJson(doc.data);
          } catch (e) {
            Log.w('Failed to deserialize Item from upc: ${doc.data["upc"]}', e);
            return null;
          }
        })
        .where((item) => item != null)
        .cast<Item>()
        .toList();
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
