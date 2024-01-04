import 'dart:async';
import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

mixin AppwriteDatabase<T> {
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  late final Databases _database;
  late final String collectionId;
  late final String databaseId;
  late final String _tag;
  final Map<String, T> _items = <String, T>{};
  String get userId;

  Iterable<T> get values => UnmodifiableListView(_items.values);
  List<T> all() => _items.values.toList();

  void constructDatabase(String tag, Databases database, String databaseId, String collectionId) {
    _database = database;
    _tag = tag;
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

  T? deserialize(Map<String, dynamic> json);

  List<T> documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            return deserialize(doc.data);
          } catch (e) {
            Log.e('$_tag: Failed to deserialize: ${doc.data}', e.toString());
            return null;
          }
        })
        .where((item) => item != null)
        .cast<T>()
        .toList();
  }

  T? get(String id) => _items[id];

  List<T> getAll(List<String> ids) {
    return ids.map((id) => _items[id]).where((element) => element != null).cast<T>().toList();
  }

  List<T> getChanges(DateTime since) {
    return values
        .where((item) => getUpdated(item) != null && getUpdated(item)!.isAfter(since))
        .toList();
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

  DateTime? getUpdated(T item);

  bool isItemValid(T item) {
    String key = getKey(item);
    return key.isNotEmpty;
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

  void put(T item, {List<String>? permissions}) {
    String key = getKey(item);

    // If the item is not valid, throw an exception
    if (!isItemValid(item)) {
      throw Exception('$_tag: Item $key is not valid.');
    }

    _items[key] = item;

    taskQueue.queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(key),
            data: serialize(item),
            permissions: permissions);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serialize(item),
              permissions: permissions);
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(key),
              data: serialize(item),
              permissions: permissions);
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

  Map<String, dynamic> serialize(T item);

  String uniqueDocumentId(String id) {
    if (userId.isEmpty) {
      throw Exception('$_tag: User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, id);
  }
}
