import 'package:repository/database/database.dart';
import 'package:repository/model/household_member.dart';

abstract class HouseholdDatabase extends Database<HouseholdMember> {
  List<HouseholdMember> get admins;
  DateTime get created;
  String get id;

  /// Joins a household with the given ID
  ///
  /// This method should handle merging inventory items when a user joins a new household.
  /// All items in the user's inventory should be updated to have the same household ID.
  Future<void> join(String householdId);

  /// Leaves the current household
  ///
  /// This method should handle copying inventory items to the new household
  /// when a user leaves their current household.
  void leave();

  /// Updates all inventory items to have the current household ID
  ///
  /// This ensures consistency across all inventory items.
  Future<void> updateInventoryHouseholdIds();
}
