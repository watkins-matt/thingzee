import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'invitation.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class Invitation {
  final String id; // A unique identifier for the invitation
  final String householdId; // Id of the household the invitation is for
  final String inviterEmail; // The email of the user who sent the invitation
  final String inviterUserId; // The id of the user who sent the invitation
  final String recipientEmail; // The email of the recipient
  @DateTimeSerializer()
  final DateTime timestamp; // When the invitation was sent
  @InvitationStatusSerializer()
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

  factory Invitation.fromJson(Map<String, dynamic> json) => _$InvitationFromJson(json);

  Invitation copyWith({
    String? id,
    String? householdId,
    String? inviterEmail,
    String? inviterUserId,
    String? recipientEmail,
    DateTime? timestamp,
    InvitationStatus? status,
  }) {
    return Invitation(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => _$InvitationToJson(this);
}

enum InvitationStatus { pending, accepted, rejected }

class InvitationStatusSerializer implements JsonConverter<InvitationStatus, int> {
  const InvitationStatusSerializer();

  @override
  InvitationStatus fromJson(int json) => InvitationStatus.values[json];

  @override
  int toJson(InvitationStatus status) => status.index;
}

extension InvitationMerge on Invitation {
  Invitation merge(Invitation other) {
    if (id != other.id) {
      throw Exception('Cannot merge invitations with different IDs.');
    }

    // Determine the newer invitation based on the timestamp.
    final newerInvitation = other.timestamp.isAfter(timestamp) ? other : this;

    // Resolve which status should be kept.
    final resolvedStatus = resolveStatus(status, other.status);

    return Invitation(
      id: id, // The ID should be the same for both and thus doesn't change.
      householdId: newerInvitation.householdId,
      inviterEmail: newerInvitation.inviterEmail,
      inviterUserId: newerInvitation.inviterUserId,
      recipientEmail: newerInvitation.recipientEmail,
      timestamp: newerInvitation.timestamp, // Use the timestamp from the newer invitation.
      status: resolvedStatus, // Use the resolved status.
    );
  }

  // A helper method to resolve the status when merging two invitations.
  InvitationStatus resolveStatus(InvitationStatus first, InvitationStatus second) {
    // Here's an example of how you might prioritize certain statuses.
    // The exact logic will depend on how you want to handle merging.
    if (first == InvitationStatus.accepted || second == InvitationStatus.accepted) {
      return InvitationStatus.accepted;
    } else if (first == InvitationStatus.rejected || second == InvitationStatus.rejected) {
      return InvitationStatus.rejected;
    }
    return first; // If both are pending, or any other case, return the status of the first.
  }
}
