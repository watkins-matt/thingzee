import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/household_database.dart';
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
        super(repo.household.all());

  void addMember(String name, String email, {bool isAdmin = false}) {
    final member =
        HouseholdMember(name: name, email: email, isAdmin: isAdmin, householdId: household.id);
    household.put(member);
    state = household.all();
  }

  void leave() {
    household.leave();
    state = household.all();
  }

  void refreshMembers() {
    state = household.all();
  }
}
