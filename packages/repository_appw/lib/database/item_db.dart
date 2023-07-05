import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:collection/collection.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class AppwriteItemDatabase extends ItemDatabase {
  static const maxRetries = 3;
  bool _online = false;
  final _items = <String, Item>{};
  final _taskQueue = <_QueueTask>[];
  final Databases _database;
  final String collectionId;
  final String databaseId;
  String userId = '';
  DateTime? lastSync;

  AppwriteItemDatabase(this._database, this.databaseId, this.collectionId);

  bool get online => _online;

  @override
  List<Item> all() => _items.values.toList();

  @override
  void delete(Item item) {
    _items.remove(item.upc);
    queueTask(() async => await _database.deleteDocument(
        databaseId: databaseId, collectionId: collectionId, documentId: item.upc));
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

  void handleConnectionChange(bool online, Session session) {
    if (online) {
      _online = true;
      userId = session.userId;
      sync();
      scheduleMicrotask(_processQueue);
    } else {
      _online = false;
      userId = '';
      _taskQueue.clear();
    }
  }

  Future<void> partialSync() async {
    Stopwatch stopwatch = Stopwatch()..start();

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
      print(e);
    }

    stopwatch.stop();
    final elapsed = stopwatch.elapsed.inMilliseconds;
    log('Partial sync completed in ${elapsed / 1000} seconds.');
    lastSync = DateTime.now();
  }

  @override
  void put(Item item) {
    _items[item.upc] = item;

    queueTask(() async {
      try {
        final documents = await _database
            .listDocuments(databaseId: databaseId, collectionId: collectionId, queries: [
          Query.equal('upc', [item.upc]),
        ]);

        if (documents.total > 0) {
          // If document exists, update it
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: item.toJson()..['user_id'] = userId);
        } else {
          // If document does not exist, create it
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: item.toJson()..['user_id'] = userId);
        }
      } catch (e) {
        print('Failed to put item: $e');
        // Removing the item from local cache since we
        // failed to add it to the database
        _items.remove(item.upc);
        rethrow;
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  @override
  List<Item> search(String string) {
    return _items.values.where((item) => item.name.contains(string)).toList();
  }

  Future<void> sync() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      DocumentList response =
          await _database.listDocuments(databaseId: databaseId, collectionId: collectionId);
      var newItems = _documentsToList(response);
      _items.clear();
      for (final item in newItems) {
        _items[item.upc] = item;
      }
    } on AppwriteException catch (e) {
      print(e);
    }

    stopwatch.stop();
    final elapsed = stopwatch.elapsed.inMilliseconds;
    log('Item sync completed in ${elapsed / 1000} seconds.');
    lastSync = DateTime.now();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('User ID is empty, cannot generate unique document ID');
    }

    return '$userId-$upc';
  }

  List<Item> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return Item.fromJson(doc.data);
    }).toList();
  }

  Future<void> _processQueue() async {
    while (_taskQueue.isNotEmpty) {
      _QueueTask task = _taskQueue.first;

      if (task.retries >= maxRetries) {
        print('Failed to execute task after $maxRetries attempts, removing from queue');
        _taskQueue.removeAt(0);
        continue;
      }

      try {
        await task.operation();
        _taskQueue.removeAt(0); // Successfully completed the task, so we remove it.
      } catch (e) {
        print('Failed to execute task: $e. Retry attempt ${task.retries + 1}');
        task.retries += 1;
      }
    }
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
