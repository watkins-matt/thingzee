import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/invitation_database.dart';
import 'package:repository/model/invitation.dart';
import 'package:thingzee/main.dart';

// Provider that only creates InvitationState when repository is ready
final invitationStateProvider = Provider<InvitationState?>((ref) {
  final cloudRepoAsync = ref.watch(cloudRepoProvider);

  return cloudRepoAsync
      .whenData(
        (cloudRepo) => InvitationState(cloudRepo),
      )
      .valueOrNull;
});

final invitationsProvider =
    StateNotifierProvider<InvitationState, List<Invitation>>((ref) {
  // This will be null if the Future isn't resolved yet
  return ref.watch(invitationStateProvider) ?? InvitationState.empty();
});

class InvitationState extends StateNotifier<List<Invitation>> {
  final CloudRepository? cloudRepo;

  InvitationState(this.cloudRepo)
      : super(cloudRepo != null ? cloudRepo.invitation.pendingInvites() : []);

  // Empty state constructor for when repo isn't ready yet
  InvitationState.empty()
      : cloudRepo = null,
        super([]);

  bool get canSendInvites =>
      cloudRepo?.isMultiUser == true &&
      cloudRepo?.isUserVerified == true &&
      cloudRepo?.loggedIn == true;

  void acceptInvite(Invitation invitation) {
    if (cloudRepo == null) return;
    cloudRepo!.invitation.accept(invitation);
    refreshInvitations();
  }

  bool isUserInvited(String email) {
    if (cloudRepo == null) return false;
    InvitationDatabase invitation = cloudRepo!.invitation;
    List<Invitation> invites = invitation.pendingInvites();
    return invites.any((element) => element.recipientEmail == email);
  }

  bool isUserSelf(String email) => cloudRepo?.userEmail == email;

  void refreshInvitations() {
    if (cloudRepo == null) return;
    state = cloudRepo!.invitation.pendingInvites();
  }

  void sendInvite(String recipientEmail) {
    if (cloudRepo == null) return;
    if (!canSendInvites) return;

    // The user interface should prevent users from inviting themselves.
    // This exception shouldn't occur under normal circumstances.
    if (isUserSelf(recipientEmail)) {
      throw Exception('User attempted to send an invitation to themselves.');
    }

    cloudRepo!.invitation.send(cloudRepo!.userEmail, recipientEmail);
    refreshInvitations();
  }

  void cancelInvite(Invitation invitation) {
    if (cloudRepo == null) return;
    cloudRepo!.invitation.delete(invitation);
    refreshInvitations();
  }

  void declineInvite(Invitation invitation) {
    if (cloudRepo == null) return;
    // Using delete for declining as per the current implementation pattern
    cloudRepo!.invitation.delete(invitation);
    refreshInvitations();
  }
}
