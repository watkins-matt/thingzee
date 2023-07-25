import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/cloud/invitation_database.dart';
import 'package:repository/model/cloud/invitation.dart';
import 'package:uuid/uuid.dart';

class AppwriteInvitationDatabase extends InvitationDatabase {
  static const maxRetries = 3;
  bool _online = false;
  bool _processingQueue = false;
  DateTime? _lastRateLimitHit;
  DateTime? lastSync;
  final String lastSyncKey = 'AppwriteInvitationDatabase.lastSync';
  final _invitations = <String, Invitation>{};
  final _taskQueue = <_QueueTask>[];
  final Databases _database;
  final String collectionId;
  final String databaseId;
  final String userEmail;
  final String householdId;
  String userId = '';

  AppwriteInvitationDatabase(
    this._database,
    this.databaseId,
    this.collectionId,
    this.userEmail,
    this.householdId,
  );

  @override
  bool get hasInvitations => _invitations.isNotEmpty;

  bool get online => _online;

  @override
  int get pendingInviteCount => pendingInvites().length;

  @override
  void accept(Invitation invitation) {
    final updatedInvitation = invitation.copyWith(status: InvitationStatus.accepted);
    _invitations[invitation.id] = updatedInvitation;
    queueTask(() async {
      await _database.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: invitation.id,
        data: updatedInvitation.toJson(),
      );
    });
  }

  @override
  void delete(Invitation invitation) {
    _invitations.remove(invitation.id);
    queueTask(() async {
      await _database.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: invitation.id,
      );
    });
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
  List<Invitation> pendingInvites() {
    return _invitations.values
        .where((invitation) => invitation.status == InvitationStatus.pending)
        .toList();
  }

  void queueTask(Future<void> Function() operation) {
    _taskQueue.add(_QueueTask(operation));
    scheduleMicrotask(_processQueue);
  }

  @override
  Invitation send(String email) {
    final invitation = Invitation(
      id: Uuid().v4(),
      householdId: householdId,
      inviterEmail: userEmail,
      inviterUserId: userId,
      recipientEmail: email,
      timestamp: DateTime.now(),
      status: InvitationStatus.pending,
    );
    _invitations[invitation.id] = invitation;
    queueTask(() async {
      await _database.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: invitation.id,
        data: invitation.toJson(),
      );
    });
    return invitation;
  }

  Future<void> sync() async {
    if (!_online) return;

    final timer = Log.timerStart();
    String? cursor;
    List<Invitation> allInvitations = [];

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
        allInvitations.addAll(items);

        if (response.documents.isNotEmpty) {
          cursor = response.documents.last.$id;
        }
      } while (response.documents.isNotEmpty);

      _invitations.clear();
      for (final invitation in allInvitations) {
        _invitations[invitation.id] = invitation;
      }
    } on AppwriteException catch (e) {
      Log.e('Failed to sync invitations: [AppwriteException]', e.message);
    }

    Log.timerEnd(timer, 'Appwrite: Invitations synced in \$seconds seconds.');
  }

  List<Invitation> _documentsToList(DocumentList documentList) {
    return documentList.documents.map((doc) {
      return Invitation.fromJson(doc.data);
    }).toList();
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
          Log.e('Failed to execute task after $maxRetries attempts.');
          continue;
        }

        try {
          await task.operation();
        } on AppwriteException catch (e) {
          if (e.code == 429) {
            Log.e('Rate limit hit. Pausing queue processing.');
            _lastRateLimitHit = DateTime.now();
            _taskQueue.add(task);
          } else {
            Log.e(
                'Failed to execute task: [AppwriteException] ${e.message}. Retry attempt ${task.retries + 1}');
            task.retries += 1;
            _taskQueue.add(task);
          }
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
