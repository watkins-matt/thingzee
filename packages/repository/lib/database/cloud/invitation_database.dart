import 'package:repository/model/cloud/invitation.dart';

abstract class InvitationDatabase {
  bool get hasInvitations;
  void accept(Invitation invitation);
  void delete(Invitation invitation);
  List<Invitation> pendingInvites();
  Invitation send(String email);
}
