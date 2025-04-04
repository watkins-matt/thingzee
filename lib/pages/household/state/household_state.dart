import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/main.dart';

final householdProvider =
    StateNotifierProvider<HouseholdState, List<HouseholdMember>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return HouseholdState(repo);
});

class HouseholdState extends StateNotifier<List<HouseholdMember>> {
  final Repository repo;
  final HouseholdDatabase household;

  HouseholdState(this.repo)
      : household = repo.household,
        super(repo.household.all());

  void addMember(String name, String email, {bool isAdmin = false}) {
    final member = HouseholdMember(
        name: name, email: email, isAdmin: isAdmin, householdId: household.id);
    household.put(member);
    state = household.all();
  }

  /// Removes a member from the household locally (database only, not team membership)
  ///
  /// This is used primarily for data cleanup when there's inconsistency between
  /// the database and actual team membership.
  Future<void> removeMember(HouseholdMember member) async {
    try {
      Log.i('HouseholdState: Removing member ${member.email} from household');

      // Remove from local database using the deleteById method
      household.deleteById(member.uniqueKey);
      Log.i('HouseholdState: Member removed from local database');

      // Update the state to reflect the change
      state = household.all();
    } catch (e) {
      Log.e('HouseholdState: Error removing member', e);
      rethrow;
    }
  }

  void leave() {
    household.leave();
    state = household.all();
  }

  void refreshMembers() {
    state = household.all();
  }
}
