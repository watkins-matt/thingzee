import 'dart:async';
import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

mixin AppwriteDatabase<T> {
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  late final Databases _database;
  late final String collectionId;
  late final String databaseId;
  final Map<String, T> _items = <String, T>{};

  Iterable<T> get values => UnmodifiableListView(_items.values);
  List<T> all() => _items.values.toList();

  void constructDatabase(Databases database, String databaseId, String collectionId) {
    _database = database;
    databaseId = databaseId;
    collectionId = collectionId;
  }

  void delete(T item) {
    String id = getKey(item);
    _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });
  }

  void deleteAll() {
    for (final id in _items.keys.toList()) {
      deleteById(id);
    }
    _items.clear();
  }

  void deleteById(String id) {
    _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });
  }

  T? get(String id) => _items[id];

  List<T> getAll(List<String> ids) {
    return ids.map((id) => _items[id]).where((element) => element != null).cast<T>().toList();
  }

  Future<DocumentList> getDocuments(List<String> queries) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  // Abstract method that must be implemented in the class that uses this mixin.
  // It should return a unique identifier for each item.
  String getKey(T item);

  Future<DocumentList> getModifiedDocuments(DateTime? lastSyncTime) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [Query.greaterThan('lastUpdate', lastSyncTime?.millisecondsSinceEpoch ?? 0)],
    );
  }

  Map<String, T> map() => Map.unmodifiable(_items);

  // Abstract method to merge two items. Should be implemented by the class using this mixin.
  T merge(T existingItem, T newItem);

  void mergeState(List<T> newItems) {
    for (final newItem in newItems) {
      String id = getKey(newItem);
      final existingItem = _items[id];
      if (existingItem != null) {
        final mergedItem = merge(existingItem, newItem);
        _items[id] = mergedItem;
      } else {
        _items[id] = newItem;
      }
    }
  }

  void put(T item) {
    String key = getKey(item);
    _items[key] = item;

    taskQueue.queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(key),
            data: serializeItem(item));
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serializeItem(item));
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serializeItem(item));
        } else {
          Log.e('Failed to put item $key: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _items.remove(key);
          rethrow;
        }
      }
    });
  }

  void replaceState(List<T> allItems) {
    _items.clear();
    for (final item in allItems) {
      String key = getKey(item);
      _items[key] = item;
    }
  }

  List<T> search(String query);
  Map<String, dynamic> serializeItem(T item);
  String uniqueDocumentId(String id);
}
