import 'package:repository/database/database.dart';
import 'package:repository/model/invitation.dart';

abstract class InvitationDatabase implements Database<Invitation> {
  bool get hasInvitations;
  int get pendingInviteCount;
  void accept(Invitation invitation);
  List<Invitation> pendingInvites();
  Invitation send(String userEmail, String recipientEmail);
}
