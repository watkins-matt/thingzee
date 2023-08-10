import 'package:repository/model/cloud/invitation.dart';

abstract class InvitationDatabase {
  bool get hasInvitations;
  int get pendingInviteCount;
  void accept(Invitation invitation);
  void delete(Invitation invitation);
  List<Invitation> pendingInvites();
  Invitation send(String userEmail, String recipientEmail);
}
