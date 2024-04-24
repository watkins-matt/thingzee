import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/model/serializer_invitation_status.dart';
import 'package:util/extension/date_time.dart';

part 'invitation.g.dart';
part 'invitation.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class Invitation extends Model<Invitation> {
  // A unique identifier for the invitation
  @JsonKey(defaultValue: '')
  @override
  final String uniqueKey;

  // Id of the household the invitation is for
  @JsonKey(defaultValue: '')
  final String householdId;

  // The email of the user who sent the invitation
  @JsonKey(defaultValue: '')
  final String inviterEmail;

  // The id of the user who sent the invitation
  @JsonKey(defaultValue: '')
  final String inviterUserId;

  // The email of the recipient
  @JsonKey(defaultValue: '')
  final String recipientEmail;

  // Status of the invitation
  @InvitationStatusSerializer()
  final InvitationStatus status;

  Invitation({
    required this.uniqueKey,
    required this.householdId,
    required this.inviterEmail,
    required this.inviterUserId,
    required this.recipientEmail,
    this.status = InvitationStatus.pending,
    super.created,
    super.updated,
  });
  factory Invitation.fromJson(Map<String, dynamic> json) => _$InvitationFromJson(json);

  @override
  Invitation copyWith({
    String? id,
    String? householdId,
    String? inviterEmail,
    String? inviterUserId,
    String? recipientEmail,
    InvitationStatus? status,
    DateTime? created,
    DateTime? updated,
  }) {
    return Invitation(
      uniqueKey: id ?? this.uniqueKey,
      householdId: householdId ?? this.householdId,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      status: status ?? this.status,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Invitation other) {
    return uniqueKey == other.uniqueKey &&
        householdId == other.householdId &&
        inviterEmail == other.inviterEmail &&
        inviterUserId == other.inviterUserId &&
        recipientEmail == other.recipientEmail &&
        status == other.status;
  }

  @override
  Invitation merge(Invitation other) {
    var result = _$mergeInvitation(this, other);
    result = result.copyWith(
      status: resolveStatus(status, other.status),
    );

    return result;
  }

  // A helper method to resolve the status when merging two invitations.
  InvitationStatus resolveStatus(InvitationStatus first, InvitationStatus second) {
    if (first == InvitationStatus.accepted || second == InvitationStatus.accepted) {
      return InvitationStatus.accepted;
    } else if (first == InvitationStatus.rejected || second == InvitationStatus.rejected) {
      return InvitationStatus.rejected;
    }
    return first; // If both are pending, or any other case, return the status of the first.
  }

  @override
  Map<String, dynamic> toJson() => _$InvitationToJson(this);
}

enum InvitationStatus { pending, accepted, rejected }
