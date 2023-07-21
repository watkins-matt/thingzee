import 'package:meta/meta.dart';

@immutable
class Invitation {
  final String id; // A unique identifier for the invitation
  final String householdId; // Id of the household the invitation is for
  final String inviterEmail; // The email of the user who sent the invitation
  final String inviterUserId; // The id of the user who sent the invitation
  final String recipientEmail; // The email of the recipient
  final DateTime timestamp; // When the invitation was sent
  final InvitationStatus status; // Status of the invitation

  const Invitation({
    required this.id,
    required this.householdId,
    required this.inviterEmail,
    required this.inviterUserId,
    required this.recipientEmail,
    required this.timestamp,
    this.status = InvitationStatus.pending,
  });
}

enum InvitationStatus { pending, accepted, rejected }
