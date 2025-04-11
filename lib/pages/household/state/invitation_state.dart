import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/cloud_repository.dart';
import 'package:repository/database/invitation_database.dart';
import 'package:repository/model/invitation.dart';
import 'package:repository_appw/database/invitation_db.dart';
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

      // Create an updated invitation with 'accepted' status
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.accepted,
      );

      // Update the invitation status in the database
      // This will trigger the cloud function to process team/household membership
      cloudRepo.invitation.put(updatedInvitation);

      // Update local state immediately to show acceptance
      // We'll replace the pending invitation with the accepted one
      if (state.value != null) {
        final currentInvitations = state.value!.toList();
        final index = currentInvitations.indexWhere(
            (inv) => inv.uniqueKey == invitation.uniqueKey);
        
        if (index >= 0) {
          currentInvitations[index] = updatedInvitation;
          state = AsyncValue.data(currentInvitations);
        }
      }

      // Wait a moment to allow the cloud function to process
      await Future.delayed(const Duration(seconds: 1));

      // Refresh the invitations list to get the latest state
      await refreshInvitations();

      Log.i('InvitationState: Invitation accepted successfully');
    } catch (e, stack) {
      Log.e('InvitationState: Exception accepting invitation', e, stack);
      
      // Don't rethrow here - instead just show the error but still display existing invitations
      Log.e('InvitationState: Exception accepting invitation', e, stack);
      
      // Just refresh invitations to show current state without throwing
      try {
        await refreshInvitations();
      } catch (refreshError) {
        Log.w('InvitationState: Could not refresh after error: $refreshError');
      }
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
    // Keep the current state, don't set to loading
    // This prevents the UI from disappearing during refresh
    try {
      final cloudRepo = await _getCloudRepo();
      
      // First, force a sync with the remote database if we're online
      if (cloudRepo.invitation is AppwriteInvitationDatabase) {
        Log.i('InvitationState: Forcing sync with remote database');
        final appwriteDb = cloudRepo.invitation as AppwriteInvitationDatabase;
        
        // The AppwriteInvitationDatabase mixes in AppwriteSynchronizable
        if (appwriteDb.online) {
          // Force a full refresh from the server
          await appwriteDb.fetch();
          Log.i('InvitationState: Completed full sync with remote database');
        } else {
          Log.w('InvitationState: Cannot sync - device is offline');
        }
      }
      
      // Now get the updated list of pending invitations
      final invitations = cloudRepo.invitation.pendingInvites();
      Log.i('InvitationState: Retrieved ${invitations.length} pending invitations');
      
      // Only update the state once we have the new data
      state = AsyncValue.data(invitations);
    } catch (e, stack) {
      Log.e('InvitationState: Error refreshing invitations', e, stack);
      // Don't update state to error if we already have data
      // This keeps existing UI visible even if refresh fails
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
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
