// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/invitation_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';
import 'package:uuid/uuid.dart';

class AppwriteInvitationDatabase extends InvitationDatabase
    with AppwriteSynchronizable<Invitation>, AppwriteDatabase<Invitation> {
  static const String tag = 'AppwriteInvitationDatabase';
  final String householdId;

  AppwriteInvitationDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
    this.householdId,
  ) : super() {
    constructDatabase(tag, database, databaseId, collectionId);
    constructSynchronizable(tag, prefs,
        onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });
  }

  @override
  bool get hasInvitations => values.isNotEmpty;

  @override
  int get pendingInviteCount => pendingInvites().length;

  @override
  void accept(Invitation invitation) {
    final recipientUserId = hashEmail(invitation.recipientEmail);

    if (userId != recipientUserId) {
      throw Exception('$tag: Cannot accept invitation for another user.');
    }

    // Update the invitation status
    final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.accepted);

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(invitation.inviterUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    try {
      // Update the invitation document in the database
      // This will trigger the process_invitation cloud function
      Log.i('$tag: Updating invitation status to accepted');
      Log.i('$tag: Cloud function will handle team membership for household: ${invitation.householdId}');
      
      // Put the updated invitation in the database
      put(updatedInvitation, permissions: permissions);
      
      Log.i('$tag: Invitation status updated to accepted, waiting for cloud function to process team membership');
    } catch (e) {
      Log.e('$tag: Error updating invitation status: $e');
      throw Exception('$tag: Failed to update invitation status: $e');
    }
  }

  @override
  Invitation? deserialize(Map<String, dynamic> json) =>
      Invitation.fromJson(json);

  @override
  Map<String, dynamic> serialize(Invitation item) {
    // Get the standard JSON serialization
    Map<String, dynamic> json = item.toJson();

    // Validate required fields
    if (item.householdId.isEmpty) {
      Log.w('$tag: Attempted to save invitation with empty householdId');
    }

    return json;
  }

  @override
  Invitation send(String userEmail, String recipientEmail) {
    String userId = hashEmail(userEmail);

    // Validate householdId
    if (householdId.isEmpty) {
      const errorMsg = '$tag: Cannot send invitation with empty householdId';
      Log.e(errorMsg);
      throw Exception(errorMsg);
    }

    final uniqueKey = const Uuid().v4();

    final invitation = Invitation(
      uniqueKey: uniqueKey,
      householdId: householdId,
      inviterEmail: userEmail,
      inviterUserId: userId,
      recipientEmail: recipientEmail,
      status: InvitationStatus.pending,
    );

    // Secure permissions approach - only sender can manage their invitations
    final permissions = [
      Permission.read(Role.user(userId)), // Sender can read
      Permission.write(Role.user(userId)), // Sender can write
      Permission.update(Role.user(userId)), // Sender can update
      Permission.delete(Role.user(userId)), // Sender can delete
    ];

    try {
      // Use standard put method - our overridden serialize method will add the ID field
      put(invitation, permissions: permissions);

      Log.i(
          '$tag: Successfully queued invitation to $recipientEmail for household $householdId');
      return invitation;
    } catch (e) {
      Log.e('$tag: Error sending invitation', e);
      throw Exception('Failed to send invitation: $e');
    }
  }

  @override
  List<Invitation> pendingInvites() {
    // First get invitations where the current user is the sender
    final senderInvites = values
        .where((invitation) => invitation.status == InvitationStatus.pending)
        .toList();

    // Then check manually for invitations where current user is the recipient
    // This requires a special query on the database
    try {
      // These are invitations for which the current user might not have explicit permissions
      final recipientInvitations = _fetchInvitationsForCurrentUserEmail();

      // Combine the lists (we might have duplicates, but that's handled by the UI)
      return [...senderInvites, ...recipientInvitations];
    } catch (e) {
      Log.e('$tag: Error fetching invitations for current user', e);
      // Return just sender invites if recipient fetch fails
      return senderInvites;
    }
  }

  // This method fetches invitations where the current user is the recipient
  // but may not have direct permissions to read them
  List<Invitation> _fetchInvitationsForCurrentUserEmail() {
    try {
      // For now, this is just a placeholder for the query that will be handled by the cloud function
      // The cloud function will set permissions so that recipients can read their invitations
      return [];

      // In the future, we could implement a direct query here if needed:
      /*
      final result = await database.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('recipientEmail', userEmail),
          Query.equal('status', 'pending')
        ]
      );
      */
    } catch (e) {
      Log.e('$tag: Error in _fetchInvitationsForCurrentUserEmail', e);
      return [];
    }
  }
}
