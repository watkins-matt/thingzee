import 'package:appwrite/appwrite.dart';
import 'package:repository/database/cloud/invitation_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/cloud/invitation.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';
import 'package:uuid/uuid.dart';

class AppwriteInvitationDatabase extends InvitationDatabase
    with AppwriteSynchronizable<Invitation>, AppwriteDatabase<Invitation> {
  static const String TAG = 'AppwriteInvitationDatabase';
  final String householdId;

  AppwriteInvitationDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
    this.householdId,
  ) : super() {
    constructSynchronizable(TAG, prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
    constructDatabase(TAG, database, databaseId, collectionId);
  }

  @override
  bool get hasInvitations => values.isNotEmpty;

  @override
  int get pendingInviteCount => pendingInvites().length;

  @override
  void accept(Invitation invitation) {
    final recipientUserId = hashEmail(invitation.recipientEmail);

    if (userId != recipientUserId) {
      throw Exception('$TAG: Cannot accept invitation for another user.');
    }

    final response = invitation.copyWith(status: InvitationStatus.accepted, id: Uuid().v4());

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(invitation.inviterUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    put(response, permissions: permissions);
  }

  @override
  Invitation? deserialize(Map<String, dynamic> json) => Invitation.fromJson(json);

  @override
  String getKey(Invitation item) => item.id;

  @override
  DateTime? getUpdated(Invitation item) => item.timestamp;

  @override
  Invitation merge(Invitation existingItem, Invitation newItem) => existingItem.merge(newItem);

  @override
  List<Invitation> pendingInvites() {
    return values.where((invitation) => invitation.status == InvitationStatus.pending).toList();
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

    final permissions = [
      Permission.read(Role.user(userId, 'verified')),
      Permission.read(Role.user(recipientUserId, 'verified')),
      Permission.write(Role.user(userId, 'verified')),
    ];

    put(invitation, permissions: permissions);

    return invitation;
  }

  @override
  Map<String, dynamic> serialize(Invitation item) => item.toJson();
}
