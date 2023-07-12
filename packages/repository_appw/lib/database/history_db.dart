import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log;
import 'package:log/log.dart';
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
  bool _processingQueue = false;
  String userId = '';
  DateTime? lastSync;

  AppwriteHistoryDatabase(this._database, this.databaseId, this.collectionId);

  bool get online => _online;

  @override
  List<History> all() => _history.values.toList();

  @override
  void delete(History history) {
    _history.remove(history.upc);

    queueTask(() async => await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uniqueDocumentId(history.upc)));
  }

  @override
  void deleteAll() {
    for (final history in _history.values.toList()) {
      delete(history);
    }
    _history.clear();
  }

  History deserializeHistory(Map<String, dynamic> serialized) {
    return History.fromJson(jsonDecode(serialized['json']));
  }

  @override
  History? get(String upc) {
    return _history[upc];
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
  Map<String, History> map() {
    return _history;
  }

  @override
  void put(History history) {
    _history[history.upc] = history;

    queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: uniqueDocumentId(history.upc),
            data: serializeHistory(history));
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(history.upc),
              data: serializeHistory(history));
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: uniqueDocumentId(history.upc),
              data: serializeHistory(history));
        } else {
          Log.e('Failed to put history: $e');
          // Removing the history from local cache since we
          // failed to add it to the database
          _history.remove(history.upc);
          rethrow;
        }
      }
    });
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Map<String, dynamic> serializeHistory(History history) {
    Map<String, dynamic> serialized = {
      'user_id': userId,
      'upc': history.upc,
      'json': jsonEncode(history.toJson())
    };

    return serialized;
  }

  Future<void> sync() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

    final timer = Log.timerStart();
    String? cursor;
    List<History> allHistory = [];

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
        allHistory.addAll(items);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _history.clear();
      for (final history in allHistory) {
        _history[history.upc] = history;
      }
    } on AppwriteException catch (e) {
      Log.e(e);
    }

    Log.timerEnd(timer, 'Appwrite: History synced in \$seconds seconds.');
    lastSync = DateTime.now();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('User ID is empty, cannot generate unique document ID');
    }

    return '$userId-$upc';
  }

  List<History> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return deserializeHistory(doc.data);
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

    _processingQueue = false;
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
