import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository/repository.dart';
import 'package:repository_appw/database/household_db.dart';
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

  Future<void> refreshMembers() async {
    try {
      // Check if we can access the Appwrite implementation
      if (household is AppwriteHouseholdDatabase) {
        Log.i('HouseholdState: Refreshing household members. Current household ID: ${household.id}');
        final appwriteHousehold = household as AppwriteHouseholdDatabase;
        
        // First attempt to fetch team members through Appwrite Teams API
        final teamMembers = await appwriteHousehold.fetchTeamMembers();
        Log.i('HouseholdState: Team members fetched: ${teamMembers.length}. Member emails: ${teamMembers.map((m) => m.email).join(', ')}');
        
        // If we have multiple team members, use them directly
        if (teamMembers.length > 1) {
          Log.i('HouseholdState: Found ${teamMembers.length} members in the household team, using team data directly');
          state = teamMembers;
          return;
        }
        
        // If we have zero or one team member, check the database for additional members
        Log.i('HouseholdState: Only ${teamMembers.length} team member(s) found, checking database for additional household members');
        final allDatabaseMembers = await appwriteHousehold.getAllHouseholdMembers();
        Log.i('HouseholdState: Database members fetched: ${allDatabaseMembers.length}. Member emails: ${allDatabaseMembers.map((m) => m.email).join(', ')}');
        
        // Track all the unique household IDs we find
        final Set<String> householdIds = allDatabaseMembers
            .map((m) => m.householdId)
            .where((id) => id.isNotEmpty)
            .toSet();
        
        // Debug output showing all the household IDs found
        if (householdIds.isNotEmpty) {
          Log.i('HouseholdState: Found ${householdIds.length} different household IDs in database records: ${householdIds.join(', ')}');
        } else {
          Log.i('HouseholdState: No household IDs found in database records');
        }
        
        // Combine the lists, removing duplicates based on userId or email
        final combinedMembers = [...teamMembers];
        Log.i('HouseholdState: Starting with ${combinedMembers.length} team members');
        
        int addedCount = 0;
        for (final member in allDatabaseMembers) {
          // Skip if this member is already in the list (based on userId or email)
          final bool alreadyExists = combinedMembers.any((m) => 
              (m.userId.isNotEmpty && m.userId == member.userId) || 
              (m.email == member.email));
              
          if (!alreadyExists) {
            // Normalize the householdId to match the current user's householdId
            final normalizedMember = member.copyWith(householdId: household.id);
            combinedMembers.add(normalizedMember);
            addedCount++;
            Log.i('HouseholdState: Added member from database: ${normalizedMember.email} (original householdId: ${member.householdId}, normalized to: ${normalizedMember.householdId})');
          } else {
            Log.i('HouseholdState: Skipped duplicate member: ${member.email}');
          }
        }
        
        // Update state with all unique members
        Log.i('HouseholdState: Final combined members: ${combinedMembers.length} ($addedCount added from database)');
        state = combinedMembers;
        Log.i('HouseholdState: Successfully refreshed with ${combinedMembers.length} total members. Final emails: ${combinedMembers.map((m) => m.email).join(', ')}');
        return;
      } else {
        // Use standard household database implementation
        Log.i('HouseholdState: Using standard household database');
        state = household.all();
      }
    } catch (e) {
      Log.e('HouseholdState: Error refreshing members', e);
    }
  }
}
