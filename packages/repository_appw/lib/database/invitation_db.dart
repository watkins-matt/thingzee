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
    constructSynchronizable(tag, prefs, onConnectivityChange: (bool online) async {
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
    final response =
        invitation.copyWith(status: InvitationStatus.accepted, uniqueKey: const Uuid().v4());

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(invitation.inviterUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    // Add the user to the household team and update inventory
    taskQueue.queueTask(() async {
      try {
        // Create membership in the team (household)
        await _teams.createMembership(
          teamId: invitation.householdId,
          email: invitation.recipientEmail,
          roles: ['member'],
          url: 'https://thingzee.net', // Redirect URL after accepting membership
        );

        // Join the new household if we have a reference to the household database
        if (_householdDb != null) {
          try {
            // Join the new household - this will handle updating inventory items
            await _householdDb!.join(invitation.householdId);
          } catch (e) {
            Log.e('$tag: Failed to join household: $e');
            throw Exception('$tag: Failed to join household: $e');
          }
        } else {
          Log.w('$tag: Household database not set, cannot update household ID');
        }
      } on AppwriteException catch (e) {
        if (e.code == 409) {
          // User is already a member, which is fine
          // Still need to update the household ID
          if (_householdDb != null) {
            try {
              await _householdDb!.join(invitation.householdId);
            } catch (e) {
              Log.e('$tag: Failed to join household: $e');
              throw Exception('$tag: Failed to join household: $e');
            }
          } else {
            Log.w('$tag: Household database not set, cannot update household ID');
          }
        } else {
          throw Exception('$tag: Failed to add user to household: ${e.message}');
        }
      }
    });

    put(response, permissions: permissions);
  }

  @override
  Invitation? deserialize(Map<String, dynamic> json) => Invitation.fromJson(json);

  @override
  List<Invitation> pendingInvites() {
    return values.where((invitation) => invitation.status == InvitationStatus.pending).toList();
  }

  @override
  Invitation send(String userEmail, String recipientEmail) {
    String userId = hashEmail(userEmail);
    String recipientUserId = hashEmail(recipientEmail);

    final invitation = Invitation(
      uniqueKey: const Uuid().v4(),
      householdId: householdId,
      inviterEmail: userEmail,
      inviterUserId: userId,
      recipientEmail: recipientEmail,
      status: InvitationStatus.pending,
    );

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(recipientUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    put(invitation, permissions: permissions);

    return invitation;
  }

  // Setter for the household database
  void setHouseholdDatabase(HouseholdDatabase db) {
    _householdDb = db;
  }
}
