import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/cloud/invitation_database.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/model/cloud/invitation.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final householdProvider = StateNotifierProvider<HouseholdState, List<HouseholdMember>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return HouseholdState(repo);
});

class HouseholdState extends StateNotifier<List<HouseholdMember>> {
  final Repository repo;
  final HouseholdDatabase household;

  HouseholdState(this.repo)
      : household = repo.household,
        super(repo.household.members);

  bool get canSendInvites => repo.isMultiUser && repo.isUserVerified && repo.loggedIn;

  void addMember(String name, String email, {bool isAdmin = false}) {
    household.addMember(name, email, isAdmin: isAdmin);
    state = household.members;
  }

  bool isUserInvited(String email) {
    assert(canSendInvites);
    CloudRepository cloudRepo = repo as CloudRepository;
    InvitationDatabase invitation = cloudRepo.invitation;

    List<Invitation> invites = invitation.pendingInvites();
    return invites.any((element) => element.recipientEmail == email);
  }

  void leave() {
    household.leave();
    state = household.members;
  }

  void sendInvite(String email) {
    assert(canSendInvites);
    CloudRepository cloudRepo = repo as CloudRepository;
    cloudRepo.invitation.send(email);
  }
}
