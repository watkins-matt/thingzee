import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:log/log.dart';
import 'package:repository/database/cloud/invitation_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/cloud/invitation.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_task_queue.dart';
import 'package:uuid/uuid.dart';

class AppwriteInvitationDatabase extends InvitationDatabase {
  static const maxRetries = 3;
  bool _online = false;
  AppwriteTaskQueue taskQueue = AppwriteTaskQueue();
  DateTime? lastSync;
  final String lastSyncKey = 'AppwriteInvitationDatabase.lastSync';
  final Preferences prefs;
  final _invitations = <String, Invitation>{};

  final Databases _database;
  final String collectionId;
  final String databaseId;
  final String householdId;

  AppwriteInvitationDatabase(
    this.prefs,
    this._database,
    this.databaseId,
    this.collectionId,
    this.householdId,
  ) {
    int? lastSyncMillis = prefs.getInt(lastSyncKey);
    if (lastSyncMillis != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  @override
  bool get hasInvitations => _invitations.isNotEmpty;

  bool get online => _online;

  @override
  int get pendingInviteCount => pendingInvites().length;

  @override
  void accept(Invitation invitation) {
    final updatedInvitation = invitation.copyWith(status: InvitationStatus.accepted);
    _invitations[invitation.id] = updatedInvitation;
    taskQueue.queueTask(() async {
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
    taskQueue.queueTask(() async {
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

      await taskQueue.runUntilComplete();
      await sync();
    } else {
      _online = false;
    }
  }

  @override
  List<Invitation> pendingInvites() {
    return _invitations.values
        .where((invitation) => invitation.status == InvitationStatus.pending)
        .toList();
  }

  @override
  Invitation send(String userEmail, String recipientEmail) {
    String userId = hashEmail(userEmail);
    String recipientUserId = hashEmail(recipientEmail);

    final invitation = Invitation(
      id: Uuid().v4(),
      householdId: householdId,
      inviterEmail: userEmail,
      inviterUserId: userId,
      recipientEmail: recipientEmail,
      timestamp: DateTime.now(),
      status: InvitationStatus.pending,
    );
    _invitations[invitation.id] = invitation;

    // Try to send the invitation
    taskQueue.queueTask(() async {
      try {
        await _database.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: invitation.id,
            data: invitation.toJson(),
            permissions: [
              Permission.read(Role.user(userId, 'verified')),
              Permission.read(Role.user(recipientUserId, 'verified')),
              Permission.write(Role.user(userId, 'verified')),
            ]);
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await _database.createDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: invitation.id,
              data: invitation.toJson(),
              permissions: [
                Permission.read(Role.user(userId, 'verified')),
                Permission.read(Role.user(recipientUserId, 'verified')),
                Permission.write(Role.user(userId, 'verified')),
              ]);
        } else if (e.code == 409) {
          await _database.updateDocument(
              databaseId: databaseId,
              collectionId: collectionId,
              documentId: invitation.id,
              data: invitation.toJson(),
              permissions: [
                Permission.read(Role.user(userId, 'verified')),
                Permission.read(Role.user(recipientUserId, 'verified')),
                Permission.write(Role.user(userId, 'verified')),
              ]);
        } else {
          Log.e('Failed to send invitation: [AppwriteException]', e.message);
          // Removing the inventory from local cache since we
          // failed to add it to the database
          _invitations.remove(invitation.id);
          rethrow;
        }
      }
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
    _updateSyncTime();
  }

  List<Invitation> _documentsToList(DocumentList documentList) {
    return documentList.documents
        .map((doc) {
          try {
            return Invitation.fromJson(doc.data);
          } catch (e) {
            Log.w('Failed to deserialize Invitation: ${doc.data["id"]}', e);
            return null;
          }
        })
        .where((invitation) => invitation != null)
        .cast<Invitation>()
        .toList();
  }

  void _updateSyncTime() {
    lastSync = DateTime.now();
    prefs.setInt(lastSyncKey, lastSync!.millisecondsSinceEpoch);
  }
}
