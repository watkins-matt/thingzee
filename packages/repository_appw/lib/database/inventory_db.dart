import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
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
  DateTime? lastSync;

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

  Future<void> handleConnectionChange(bool online, Session session) async {
    if (online) {
      _online = true;
      userId = session.userId;
      await sync();
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
          documentId: uniqueDocumentId(inv.upc),
          data: serializeInventory(inv),
        );
      } else {
        await _database.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: uniqueDocumentId(inv.upc),
          data: serializeInventory(inv),
        );
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Map<String, dynamic> serializeInventory(Inventory inv) {
    var json = inv.toJson();
    json['user_id'] = userId;
    json.remove('history');
    json.remove('units');

    return json;
  }

  Future<void> sync() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

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
    lastSync = DateTime.now();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('User ID is empty, cannot generate unique document ID');
    }

    return '$userId-$upc';
  }

  List<Inventory> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return deserializeInventory(doc.data);
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
