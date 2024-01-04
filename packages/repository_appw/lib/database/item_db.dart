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
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteItemDatabase extends ItemDatabase with AppwriteSynchronizable<Item> {
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();

  final _items = <String, Item>{};
  final Databases _database;
  final Preferences prefs;
  final String collectionId;
  final String databaseId;

  AppwriteItemDatabase(
    this.prefs,
    this._database,
    this.databaseId,
    this.collectionId,
  ) : super() {
    construct('AppwriteItemDatabase', prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
  }

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
  List<Item> documentsToList(DocumentList documents) {
    return documents.documents
        .map((doc) {
          try {
            return Item.fromJson(doc.data);
          } catch (e) {
            Log.w('Failed to deserialize Item from upc: ${doc.data["upc"]}', e);
            return null;
          }
        })
        .whereNotNull()
        .toList();
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

  @override
  Future<DocumentList> getDocuments(List<String> queries) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  @override
  Future<DocumentList> getModifiedDocuments(DateTime? lastSyncTime) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [Query.greaterThan('lastUpdate', lastSync?.millisecondsSinceEpoch ?? 0)],
    );
  }

  @override
  Map<String, Item> map() {
    return Map.unmodifiable(_items);
  }

  @override
  void mergeState(List<Item> newItems) {
    for (final newItem in newItems) {
      final existingItem = _items[newItem.upc];
      final mergedItem = existingItem?.merge(newItem) ?? newItem;
      _items[newItem.upc] = mergedItem;
    }
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
  void replaceState(List<Item> allItems) {
    _items.clear();
    for (final item in allItems) {
      _items[item.upc] = item;
    }
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

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('AppwriteItemDB: User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, upc);
  }
}
