import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log;
import 'package:collection/collection.dart';
import 'package:log/log.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class AppwriteItemDatabase extends ItemDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
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

      scheduleMicrotask(_processQueue);
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

    queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(item.upc),
            data: item.toJson()..['user_id'] = userId);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: item.toJson()..['user_id'] = userId);
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(item.upc),
              data: item.toJson()..['user_id'] = userId);
        } else {
          Log.e('Failed to put inventory: ', e);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _items.remove(item.upc);
          rethrow;
        }
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

    Log.timerEnd(timer, 'Appwrite: Items synced in \$seconds seconds.');
    lastSync = DateTime.now();
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
      Log.e(e);
    }

    Log.timerEnd(timer, 'Appwrite: Modified item sync completed in \$seconds seconds.');
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
    if (_processingQueue || !_online) {
      return;
    }
    _processingQueue = true;

    while (_taskQueue.isNotEmpty) {
      _QueueTask task = _taskQueue.removeAt(0);

      if (task.retries >= maxRetries) {
        Log.e('Failed to execute task after $maxRetries attempts.');
        continue;
      }

      try {
        await task.operation();
      } on AppwriteException catch (e) {
        if (e.code != 404 && e.code != 409) {
          Log.e('Failed to execute task: $e. Retry attempt ${task.retries + 1}');
          task.retries += 1;
          _taskQueue.add(task);
        }
      }
    }

    _processingQueue = true;
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
