import 'package:json_annotation/json_annotation.dart';
import 'package:repository/model/invitation.dart';

class InvitationStatusSerializer implements JsonConverter<InvitationStatus, int> {
  const InvitationStatusSerializer();

  @override
  InvitationStatus fromJson(int json) => InvitationStatus.values[json];

  @override
  int toJson(InvitationStatus status) => status.index;
}
