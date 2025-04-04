// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
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

  final Teams _teams;

  // Reference to the household database
  HouseholdDatabase? _householdDb;

  AppwriteInvitationDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
    this.householdId,
    this._teams,
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
    final response = invitation.copyWith(
        status: InvitationStatus.accepted, uniqueKey: const Uuid().v4());

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(invitation.inviterUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    // Add the user to the household team and update inventory
    taskQueue.queueTask(() async {
      try {
        Log.i(
            '$tag: Starting to process invitation acceptance for household: ${invitation.householdId}');

        // Create membership in the team (household)
        await _teams.createMembership(
          teamId: invitation.householdId,
          email: invitation.recipientEmail,
          roles: ['member'],
          url:
              'https://thingzee.net', // Redirect URL after accepting membership
        );
        Log.i(
            '$tag: Created team membership for ${invitation.recipientEmail} in household ${invitation.householdId}');

        // Join the new household if we have a reference to the household database
        if (_householdDb != null) {
          try {
            // Join the new household - this will handle updating inventory items
            Log.i(
                '$tag: Attempting to join household ${invitation.householdId}');
            await _householdDb!.join(invitation.householdId);
            Log.i(
                '$tag: Successfully joined household ${invitation.householdId}');
          } catch (e) {
            Log.e('$tag: Failed to join household: $e');
            throw Exception('$tag: Failed to join household: $e');
          }
        } else {
          Log.w('$tag: Household database not set, cannot update household ID');
          throw Exception(
              '$tag: Household database not set, cannot join household');
        }
      } on AppwriteException catch (e) {
        if (e.code == 409) {
          // User is already a member, which is fine
          Log.i(
              '$tag: User is already a member of household ${invitation.householdId}');

          // Still need to update the household ID
          if (_householdDb != null) {
            try {
              Log.i('$tag: Updating household ID to ${invitation.householdId}');
              await _householdDb!.join(invitation.householdId);
              Log.i('$tag: Successfully updated household ID');
            } catch (e) {
              Log.e('$tag: Failed to join household: $e');
              throw Exception('$tag: Failed to join household: $e');
            }
          } else {
            Log.w(
                '$tag: Household database not set, cannot update household ID');
            throw Exception(
                '$tag: Household database not set, cannot update household ID');
          }
        } else {
          Log.e('$tag: AppwriteException: ${e.message}, code: ${e.code}');
          throw Exception(
              '$tag: Failed to add user to household: ${e.message}');
        }
      } catch (e) {
        Log.e('$tag: Unexpected error while processing invitation: $e');
        throw Exception(
            '$tag: Unexpected error while processing invitation: $e');
      }
    });

    // Update the invitation document
    Log.i('$tag: Updating invitation status to accepted');
    put(response, permissions: permissions);
  }

  @override
  Invitation? deserialize(Map<String, dynamic> json) =>
      Invitation.fromJson(json);

  @override
  Map<String, dynamic> serialize(Invitation item) {
    // Get the standard JSON serialization
    Map<String, dynamic> json = item.toJson();
    
    // Map fields to Appwrite's expected schema
    json['id'] = item.uniqueKey;  // Appwrite requires 'id' field
    
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
      final errorMsg = '$tag: Cannot send invitation with empty householdId';
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

      Log.i('$tag: Successfully queued invitation to $recipientEmail for household $householdId');
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

  // Setter for the household database
  void setHouseholdDatabase(HouseholdDatabase db) {
    _householdDb = db;
  }
}
