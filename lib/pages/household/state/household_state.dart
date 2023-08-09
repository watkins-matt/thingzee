import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/model/household_member.dart';
import 'package:thingzee/main.dart';

final householdProvider = StateNotifierProvider<HouseholdState, List<HouseholdMember>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return HouseholdState(repo.household);
});

class HouseholdState extends StateNotifier<List<HouseholdMember>> {
  final HouseholdDatabase household;

  HouseholdState(this.household) : super(household.members);

  void addMember(String name, String email, {bool isAdmin = false}) {
    household.addMember(name, email, isAdmin: isAdmin);
    state = household.members;
  }

  void leave() {
    household.leave();
    state = household.members;
  }
}
