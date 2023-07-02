import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:collection/collection.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class AppwriteItemDatabase extends ItemDatabase {
  static const maxRetries = 3;
  final Databases _database;
  final String databaseId;
  final String collectionId;
  final _taskQueue = <_QueueTask>[];
  final _items = <String, Item>{};
  bool _online = false;

  AppwriteItemDatabase(this._database, this.databaseId, this.collectionId);

  bool get online => _online;

  set online(bool value) {
    _online = value;
    if (_online) {
      sync();
      scheduleMicrotask(_processQueue);
    } else {
      _taskQueue.clear();
    }
  }

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
  Optional<Item> get(String upc) {
    return Optional.fromNullable(_items[upc]);
  }

  @override
  List<Item> getAll(List<String> upcs) {
    return upcs.map((upc) => _items[upc]).whereNotNull().toList();
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
              documentId: item.upc,
              data: item.toJson());
        } else {
          // If document does not exist, create it
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: item.upc,
              data: item.toJson());
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
