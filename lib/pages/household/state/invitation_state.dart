import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/invitation_database.dart';
import 'package:repository/model/invitation.dart';
import 'package:thingzee/main.dart';

final invitationsProvider = StateNotifierProvider<InvitationState, List<Invitation>>((ref) {
  final repo = ref.watch(repositoryProvider);
  CloudRepository cloudRepo = repo as CloudRepository;
  return InvitationState(cloudRepo);
});

class InvitationState extends StateNotifier<List<Invitation>> {
  final CloudRepository cloudRepo;

  InvitationState(this.cloudRepo) : super(cloudRepo.invitation.pendingInvites());
  bool get canSendInvites =>
      cloudRepo.isMultiUser && cloudRepo.isUserVerified && cloudRepo.loggedIn;

  void acceptInvite(Invitation invitation) {
    cloudRepo.invitation.accept(invitation);
    refreshInvitations();
  }

  bool isUserInvited(String email) {
    assert(canSendInvites);
    InvitationDatabase invitation = cloudRepo.invitation;
    List<Invitation> invites = invitation.pendingInvites();
    return invites.any((element) => element.recipientEmail == email);
  }

  bool isUserSelf(String email) => cloudRepo.userEmail == email;

  void refreshInvitations() {
    state = cloudRepo.invitation.pendingInvites();
  }

  void sendInvite(String recipientEmail) {
    assert(canSendInvites);

    // The user interface should prevent users from inviting themselves.
    // This exception shouldn't occur under normal circumstances.
    if (isUserSelf(recipientEmail)) {
      throw Exception('User attempted to send an invitation to themselves.');
    }

    cloudRepo.invitation.send(cloudRepo.userEmail, recipientEmail);
    refreshInvitations();
  }
}
