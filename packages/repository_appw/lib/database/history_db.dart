import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';

class AppwriteHistoryDatabase extends HistoryDatabase {
  static const String lastSyncKey = 'AppwriteHistoryDatabase.lastSync';
  bool _online = false;

  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  DateTime? lastSync;
  final _history = <String, History>{};
  final Databases _database;
  final Preferences prefs;
  final String collectionId;
  final String databaseId;
  String userId = '';

  AppwriteHistoryDatabase(this.prefs, this._database, this.databaseId, this.collectionId) {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  bool get online => _online;

  @override
  List<History> all() => _history.values.toList();

  @override
  void delete(History history) {
    _history.remove(history.upc);

    taskQueue.queueTask(() async => await _database.deleteDocument(
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

  History? deserializeHistory(Map<String, dynamic> serialized) {
    try {
      return History.fromJson(jsonDecode(serialized['json']));
    } catch (e) {
      Log.w('Failed to deserialize History object for upc ${serialized["upc"]}. Error: $e');
      _history.remove(serialized['upc']);
      return null;
    }
  }

  @override
  History? get(String upc) {
    return _history[upc];
  }

  Future<void> handleConnectionChange(bool online, Session? session) async {
    if (online && session != null) {
      _online = true;
      userId = session.userId;

      await taskQueue.runUntilComplete();
      await sync();
    } else {
      _online = false;
      userId = '';
    }
  }

  @override
  Map<String, History> map() {
    return Map.unmodifiable(_history);
  }

  @override
  void put(History history) {
    _history[history.upc] = history;

    taskQueue.queueTask(() async {
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
          Log.e('Failed to put history ${history.upc}: [AppwriteException]', e.message);
          rethrow;
        }
      }
    });
  }

  Map<String, dynamic> serializeHistory(History history) {
    Map<String, dynamic> serialized = {
      'userId': userId,
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
      Log.e('Failed to sync history: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: History synced in \$seconds seconds.');
    _updateSyncTime();
  }

  String uniqueDocumentId(String upc) {
    if (userId.isEmpty) {
      throw Exception('User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, upc);
  }

  List<History> _documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          return deserializeHistory(doc.data);
        })
        .where((history) => history != null)
        .cast<History>()
        .toList();
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
