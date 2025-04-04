import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/invitation_database.dart';
import 'package:repository/model/invitation.dart';
import 'package:thingzee/main.dart';

final invitationsProvider =
    AsyncNotifierProvider<InvitationState, List<Invitation>>(
        () => InvitationState());

class InvitationState extends AsyncNotifier<List<Invitation>> {
  @override
  Future<List<Invitation>> build() async {
    final cloudRepo = await ref.watch(cloudRepoProvider.future);
    return cloudRepo.invitation.pendingInvites();
  }

  Future<CloudRepository> _getCloudRepo() async {
    return await ref.read(cloudRepoProvider.future);
  }

  bool get canSendInvites =>
      state.whenOrNull(
        data: (_) => true,
      ) ??
      false;

  Future<void> acceptInvite(Invitation invitation) async {
    final cloudRepo = await _getCloudRepo();

    // First, mark invitation as processing locally to provide immediate feedback
    state = const AsyncValue.loading();

    try {
      Log.i('InvitationState: Accepting invitation ${invitation.uniqueKey}');

      // Use the existing accept method, which will trigger database events
      // that the cloud function will react to
      cloudRepo.invitation.accept(invitation);

      // Wait a moment to allow the cloud function to process
      await Future.delayed(const Duration(seconds: 1));

      // Update the household members after joining a new household
      // We need to reload all data since the household ID changed
      await cloudRepo.fetch();

      // Refresh the invitations list
      await refreshInvitations();

      Log.i('InvitationState: Invitation accepted successfully');
    } catch (e, stack) {
      Log.e('InvitationState: Exception accepting invitation', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> declineInvite(Invitation invitation) async {
    state = const AsyncValue.loading();

    try {
      Log.i('InvitationState: Declining invitation ${invitation.uniqueKey}');

      final cloudRepo = await _getCloudRepo();

      // Create updated invitation with 'rejected' status (not 'declined')
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.rejected,
      );

      // Update the invitation in the database
      // Since there's no direct 'decline' method, we'll update the invitation directly
      cloudRepo.invitation.put(updatedInvitation);

      // Refresh local invitations list
      await refreshInvitations();

      Log.i('InvitationState: Invitation declined successfully');
    } catch (e, stack) {
      Log.e('InvitationState: Error declining invitation', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> isUserInvited(String email) async {
    final cloudRepo = await _getCloudRepo();
    if (!(cloudRepo.isMultiUser &&
        cloudRepo.isUserVerified &&
        cloudRepo.loggedIn)) {
      return false;
    }
    InvitationDatabase invitation = cloudRepo.invitation;
    List<Invitation> invites = invitation.pendingInvites();
    return invites.any((element) => element.recipientEmail == email);
  }

  Future<bool> isUserSelf(String email) async {
    final cloudRepo = await _getCloudRepo();
    return cloudRepo.userEmail == email;
  }

  Future<void> refreshInvitations() async {
    state = const AsyncValue.loading();
    try {
      final cloudRepo = await _getCloudRepo();
      state = AsyncValue.data(cloudRepo.invitation.pendingInvites());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancelInvitation(Invitation invitation) async {
    state = const AsyncValue.loading();

    try {
      Log.i('InvitationState: Canceling invitation ${invitation.uniqueKey}');

      final cloudRepo = await _getCloudRepo();

      // Create updated invitation with 'rejected' status since there's no 'canceled' status
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.rejected,
      );

      // Update the invitation in the database
      cloudRepo.invitation.put(updatedInvitation);

      // Refresh local invitations list
      await refreshInvitations();

      Log.i('InvitationState: Invitation canceled successfully');
    } catch (e, stack) {
      Log.e('InvitationState: Error canceling invitation', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendInvite(String recipientEmail) async {
    final cloudRepo = await _getCloudRepo();
    if (!(cloudRepo.isMultiUser &&
        cloudRepo.isUserVerified &&
        cloudRepo.loggedIn)) {
      throw Exception('User cannot send invites in current state');
    }

    // The user interface should prevent users from inviting themselves.
    // This exception shouldn't occur under normal circumstances.
    if (cloudRepo.userEmail == recipientEmail) {
      throw Exception('User attempted to send an invitation to themselves.');
    }

    cloudRepo.invitation.send(cloudRepo.userEmail, recipientEmail);
    await refreshInvitations();
  }
}
