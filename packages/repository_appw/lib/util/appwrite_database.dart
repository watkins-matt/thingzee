import 'dart:async';
import 'dart:collection';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences, Model;
import 'package:log/log.dart';
import 'package:repository/database/database.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';
import 'package:util/extension/date_time.dart';

mixin AppwriteDatabase<T extends Model> on Database<T> {
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  late final Databases _database;
  late final String collectionId;
  late final String databaseId;
  late final String _tag;
  final Map<String, T> _items = <String, T>{};
  String get userId;

  Iterable<T> get values => UnmodifiableListView(_items.values);

  @override
  List<T> all() => _items.values.toList();

  void constructDatabase(String tag, Databases database, String databaseId, String collectionId) {
    _database = database;
    _tag = tag;
    this.databaseId = databaseId;
    this.collectionId = collectionId;
  }

  @override
  void delete(T item) {
    String id = item.id;
    _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });

    replicateOperation((replica) async {
      replica.delete(item);
    });

    callHooks(item, DatabaseHookType.delete);
  }

  @override
  void deleteAll() {
    for (final id in _items.keys.toList()) {
      deleteById(id);
    }
    _items.clear();

    replicateOperation((replica) async {
      replica.deleteAll();
    });

    callHooks(null, DatabaseHookType.deleteAll);
  }

  @override
  void deleteById(String id) {
    final item = _items.remove(id);
    taskQueue.queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(id),
      );
    });

    replicateOperation((replica) async {
      replica.deleteById(id);
    });

    if (item != null) {
      callHooks(item, DatabaseHookType.delete);
    }
  }

  T? deserialize(Map<String, dynamic> json);

  List<T> documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            T? result = deserialize(doc.data);

            if (result != null) {
              final created = DateTime.parse(doc.data['\$createdAt']);
              final updated = DateTime.parse(doc.data['\$updatedAt']);

              // Note that we also use the oldest updated field because
              // one may have initialized to the default of DateTime.now()
              result = result.copyWith(
                  created: result.created.older(created), updated: result.updated.older(updated));
            }

            return result;
          } catch (e) {
            Log.e('$_tag: Failed to deserialize: ${doc.data}', e.toString());
            return null;
          }
        })
        .where((item) => item != null)
        .cast<T>()
        .toList();
  }

  @override
  T? get(String id) => _items[id];

  @override
  List<T> getAll(List<String> ids) {
    return ids.map((id) => _items[id]).where((element) => element != null).cast<T>().toList();
  }

  @override
  List<T> getChanges(DateTime since) {
    return values.where((item) => item.updated != null && item.updated!.isAfter(since)).toList();
  }

  Future<DocumentList> getDocuments(List<String> queries) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  Future<DocumentList> getModifiedDocuments(DateTime? lastSyncTime) async {
    return await _database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [Query.greaterThan('updated', lastSyncTime?.millisecondsSinceEpoch ?? 0)],
    );
  }

  bool isItemValid(T item) {
    String key = item.id;
    return key.isNotEmpty;
  }

  @override
  Map<String, T> map() => Map.unmodifiable(_items);

  void mergeState(List<T> newItems) {
    for (final newItem in newItems) {
      String id = newItem.id;
      final existingItem = _items[id];
      if (existingItem != null) {
        final mergedItem = existingItem.merge(newItem);
        _items[id] = mergedItem;
      } else {
        _items[id] = newItem;
      }
    }
  }

  @override
  void put(T item, {List<String>? permissions}) {
    String key = item.id;

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
          Log.e('$_tag: Failed to put item $key: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _items.remove(key);
          rethrow;
        }
      }
    });

    replicateOperation((replica) async {
      replica.put(item);
    });

    callHooks(item, DatabaseHookType.put);
  }

  void replaceState(List<T> allItems) {
    _items.clear();
    for (final item in allItems) {
      String key = item.id;
      _items[key] = item;
    }
  }

  Map<String, dynamic> serialize(T item) => item.toJson();

  String uniqueDocumentId(String id) {
    if (userId.isEmpty) {
      throw Exception('$_tag: User ID is empty, cannot generate unique document ID.');
    }

    return hashUsernameBarcode(userId, id);
  }
}
