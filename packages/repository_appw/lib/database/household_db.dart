import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/cloud/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/cloud/household.dart';
import 'package:uuid/uuid.dart';

class AppwriteHouseholdDatabase extends HouseholdDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
  DateTime? _lastRateLimitHit;
  final _taskQueue = <_QueueTask>[];
  final Databases _database;
  final Preferences prefs;
  final String collectionId;
  final String databaseId;
  final Teams _teams;
  String userId = '';
  Household? _household;

  AppwriteHouseholdDatabase(
      this._teams, this._database, this.databaseId, this.collectionId, this.prefs);

  @override
  Household? get household {
    return _household;
  }

  @override
  Household create() {
    final uuid = Uuid().v4();
    final creationDate = DateTime.now();

    queueTask(() async {
      final team = await _teams.create(teamId: uuid, name: '$uuid');

      // After creating the team, create a document in the household database
      await _database.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: uuid,
        data: {
          'id': team.$id,
          'timestamp': creationDate.toIso8601String(),
          'userIds': [userId],
          'adminIds': [userId],
          'names': [],
        },
      );
      await prefs.setString('householdId', uuid);
    });

    return Household(
      id: uuid,
      timestamp: creationDate,
      userIds: [userId],
      adminIds: [userId],
      names: [],
    );
  }

  Future<void> handleConnectionChange(bool online, Session? session) async {
    if (online && session != null) {
      _online = true;
      userId = session.userId;
      await sync();
      scheduleMicrotask(_processQueue);
    } else {
      _online = false;
      userId = '';
    }
  }

  @override
  void leave() {
    queueTask(() async {
      // Logic to leave the household:
      // 1. Remove the user from the team.
      // 2. Delete or update the household document in the database.
      // 3. Update the preferences to remove householdId.
    });
    prefs.remove('householdId');
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  Future<void> sync() async {
    if (!_online) return;

    final timer = Log.timerStart();

    try {
      final String householdId = prefs.getString('householdId') ?? '';
      if (householdId.isEmpty) {
        throw Exception('Household ID not found in preferences.');
      }

      final Document response = await _database.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: householdId,
      );

      _household = Household.fromJson(response.data);
    } on AppwriteException catch (e) {
      Log.e('Failed to sync household: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: Household synced in \$seconds seconds.');
  }

  Future<void> _processQueue() async {
    if (_processingQueue || !_online) return;
    _processingQueue = true;

    try {
      while (_taskQueue.isNotEmpty) {
        if (_lastRateLimitHit != null) {
          final difference = DateTime.now().difference(_lastRateLimitHit!);
          if (difference < Duration(minutes: 1)) {
            final timeToWait = Duration(minutes: 1) - difference;
            await Future.delayed(timeToWait);
            _lastRateLimitHit = null;
          }
        }

        _QueueTask task = _taskQueue.removeAt(0);

        if (task.retries >= maxRetries) {
          // Log the error: Failed to execute task after $maxRetries attempts.
          continue;
        }

        try {
          await task.operation();
        } catch (e) {
          // Adjust the error handling based on the exceptions you expect
          task.retries += 1;
          _taskQueue.add(task);
        }
      }
    } finally {
      _processingQueue = false;
    }
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
