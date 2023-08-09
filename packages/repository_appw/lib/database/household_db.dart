import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:uuid/uuid.dart';

class AppwriteHouseholdDatabase extends HouseholdDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
  DateTime? _lastRateLimitHit;
  DateTime? lastSync;
  final _taskQueue = <_QueueTask>[];
  final Databases _database;
  final List<HouseholdMember> _members = [];
  final Preferences prefs;
  final String collectionId;
  final String databaseId;
  final Teams _teams;
  late final DateTime _created;
  late final String _householdId;
  String lastSyncKey = 'AppwriteHouseholdDatabase.lastSync';
  String userId = '';

  AppwriteHouseholdDatabase(
      this._teams, this._database, this.databaseId, this.collectionId, this.prefs) {
    // Update the last sync time
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }

    // Update the household information
    if (!prefs.containsKey('household_id') || !prefs.containsKey('household_created')) {
      _createNewHousehold();
    } else {
      _loadHousehold();
    }
  }

  @override
  List<HouseholdMember> get admins => _members.where((element) => element.isAdmin).toList();

  @override
  DateTime get created => _created;

  @override
  String get id => _householdId;

  @override
  List<HouseholdMember> get members => _members;

  @override
  void addMember(String name, String email, {String? id, bool isAdmin = false}) {
    if (id != null && _members.any((element) => element.userId == id)) {
      throw Exception('User already exists in household.');
    }

    if (id != null && id.isEmpty) {
      Log.w('AppwriteHouseholdDatabase: User ID an empty string. Defaulting to unique id.');
      id = const Uuid().v4();
    }

    final member = HouseholdMember(
      email: email,
      householdId: _householdId,
      name: name,
      isAdmin: isAdmin,
      userId: id ?? const Uuid().v4(),
    );

    _members.add(member);

    queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: member.userId,
            data: serializeMember(member));
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: member.userId,
              data: serializeMember(member));
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: member.userId,
              data: serializeMember(member));
        } else {
          Log.e('Failed to add member to household: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _members.remove(member);
          rethrow;
        }
      }
    });
  }

  @override
  List<HouseholdMember> getChanges(DateTime since) {
    return _members
        .where((member) =>
            member.timestamp.millisecondsSinceEpoch != 0 && member.timestamp.isAfter(since))
        .toList();
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

  Map<String, dynamic> serializeMember(HouseholdMember member) {
    var json = member.toJson();
    return json;
  }

  Future<void> sync() async {
    // Can't sync when offline
    if (!_online) {
      return;
    }

    final timer = Log.timerStart();
    String? cursor;
    List<HouseholdMember> allMembers = [];

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

        final members = _documentsToMembers(response);
        allMembers.addAll(members);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _members.clear();
      _members.addAll(allMembers);
    } on AppwriteException catch (e) {
      Log.e('Failed to sync household members: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: Household members synced in \$seconds seconds.');
    _updateSyncTime();
  }

  Future<void> _createNewHousehold() async {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    await prefs.setString('household_id', _householdId);
    await prefs.setInt('household_created', _created.millisecondsSinceEpoch);

    try {
      await _teams.create(teamId: _householdId, name: _householdId);
    } on AppwriteException catch (e) {
      Log.e('Failed to create team: [AppwriteException]', e.message);
      rethrow;
    }
  }

  List<HouseholdMember> _documentsToMembers(DocumentList documentList) {
    return documentList.documents.map((document) {
      return HouseholdMember.fromJson(document.data);
    }).toList();
  }

  Future<void> _loadHousehold() async {
    _householdId = prefs.getString('household_id')!;
    _created = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('household_created')!);

    // Check if the team exists, and save it or create it if necessary
    try {
      await _teams.get(teamId: _householdId);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        await _teams.create(teamId: _householdId, name: _householdId);
      } else {
        // TODO: Handle team name conflict and recreate team with a new id
        Log.e('Failed to load team: [AppwriteException]', e.message);
        rethrow;
      }
    }
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

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}

class _QueueTask {
  final Future<void> Function() operation;
  int retries = 0;

  _QueueTask(this.operation);
}
