import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/ml/history.dart';

class AppwriteHistoryDatabase extends HistoryDatabase {
  static const maxRetries = 3;
  final Databases _database;
  final String databaseId;
  final String collectionId;
  final _taskQueue = <_QueueTask>[];
  final _history = <String, History>{};
  bool _online = false;

  AppwriteHistoryDatabase(this._database, this.databaseId, this.collectionId);

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
  List<History> all() => _history.values.toList();

  @override
  void delete(History history) {
    _history.remove(history.upc);
    queueTask(() async => await _database.deleteDocument(
        databaseId: databaseId, collectionId: collectionId, documentId: history.upc));
  }

  @override
  void deleteAll() {
    for (final history in _history.values.toList()) {
      delete(history);
    }
    _history.clear();
  }

  @override
  Optional<History> get(String upc) {
    return Optional.fromNullable(_history[upc]);
  }

  @override
  Map<String, History> map() {
    return _history;
  }

  @override
  void put(History history) {
    _history[history.upc] = history;

    queueTask(() async {
      try {
        final documents = await _database
            .listDocuments(databaseId: databaseId, collectionId: collectionId, queries: [
          Query.equal('upc', [history.upc]),
        ]);

        if (documents.total > 0) {
          // If document exists, update it
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: history.upc,
              data: history.toJson());
        } else {
          // If document does not exist, create it
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: history.upc,
              data: history.toJson());
        }
      } catch (e) {
        print('Failed to put history: $e');
        // Removing the history from local cache since we
        // failed to add it to the database
        _history.remove(history.upc);
        rethrow;
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Future<void> sync() async {
    try {
      DocumentList response =
          await _database.listDocuments(databaseId: databaseId, collectionId: collectionId);
      var newHistories = _documentsToList(response);
      _history.clear();
      for (final history in newHistories) {
        _history[history.upc] = history;
      }
    } on AppwriteException catch (e) {
      print(e);
    }
  }

  List<History> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return History.fromJson(doc.data);
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