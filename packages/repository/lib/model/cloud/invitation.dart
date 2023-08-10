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
