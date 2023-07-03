import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/model/inventory.dart';

class AppwriteInventoryDatabase extends InventoryDatabase {
  static const maxRetries = 3;
  final Databases _database;
  final String databaseId;
  final String collectionId;
  final _taskQueue = <_QueueTask>[];
  final _inventory = <String, Inventory>{};
  bool _online = false;
  String userId = '';

  AppwriteInventoryDatabase(
    this._database,
    this.databaseId,
    this.collectionId,
  );

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
        documentId: inv.upc,
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

  @override
  Optional<Inventory> get(String upc) => Optional.fromNullable(_inventory[upc]);

  @override
  List<Inventory> getAll(List<String> upcs) => _inventory.entries
      .where((entry) => upcs.contains(entry.key))
      .map((entry) => entry.value)
      .toList();

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

  @override
  Map<String, Inventory> map() => Map.unmodifiable(_inventory);

  @override
  List<Inventory> outs() => _inventory.values.where((inv) => inv.restock).toList();

  @override
  void put(Inventory inv) {
    _inventory[inv.upc] = inv;

    queueTask(() async {
      final documents = await _database.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal('upc', [inv.upc]),
        ],
      );

      if (documents.total > 0) {
        await _database.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: inv.upc,
          data: inv.toJson(),
        );
      } else {
        await _database.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: inv.upc,
          data: inv.toJson(),
        );
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Future<void> sync() async {
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      DocumentList response =
          await _database.listDocuments(databaseId: databaseId, collectionId: collectionId);
      var newItems = _documentsToList(response);
      _inventory.clear();
      for (final item in newItems) {
        _inventory[item.upc] = item;
      }
    } on AppwriteException catch (e) {
      print(e);
    }

    stopwatch.stop();
    final elapsed = stopwatch.elapsed.inMilliseconds;
    log('Inventory sync completed in ${elapsed / 1000} seconds.');
  }

  List<Inventory> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return Inventory.fromJson(doc.data);
    }).toList();
  }

  void _processQueue() {
    if (_taskQueue.isEmpty) {
      return;
    }

    final task = _taskQueue.removeAt(0);

    task.operation().then((_) {
      task.retryCount = 0;
      _processQueue();
    }).catchError((e) {
      if (task.retryCount < maxRetries) {
        task.retryCount++;
        _taskQueue.insert(0, task); // Requeue the task at the front
      }
      _processQueue();
    });
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retryCount = 0;

  _QueueTask(this.operation);
}
