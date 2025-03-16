import 'package:log/log.dart';
import 'package:repository/database/household_database.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/household_member.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/household_member.ob.dart';
import 'package:repository_ob/objectbox.g.dart';
import 'package:uuid/uuid.dart';

class ObjectBoxHouseholdDatabase extends HouseholdDatabase
    with ObjectBoxDatabase<HouseholdMember, ObjectBoxHouseholdMember> {
  final Preferences prefs;
  String? _householdId;
  DateTime? _created;

  // References to other databases for updating when household changes
  InventoryDatabase? _inventoryDb;

  ObjectBoxHouseholdDatabase(Store store, this.prefs) : super() {
    init(store, ObjectBoxHouseholdMember.from, ObjectBoxHouseholdMember_.userId,
        ObjectBoxHouseholdMember_.updated);

    if (!prefs.containsKey('household_id') || !prefs.containsKey('household_created')) {
      _createNewHousehold();
    } else {
      _loadHousehold();
    }
  }

  @override
  List<HouseholdMember> get admins {
    final query = box.query(ObjectBoxHouseholdMember_.isAdmin.equals(true)).build();
    final results = query.find();
    query.close();
    return results.map(convert).toList();
  }

  @override
  DateTime get created => _created!;

  @override
  String get id => _householdId!;

  @override
  Future<void> join(String householdId) async {
    // Store the old household ID
    final oldHouseholdId = _householdId;

    try {
      // Update the household ID
      _householdId = householdId;
      _created = DateTime.now();

      // Save to preferences
      await prefs.setString('household_id', _householdId!);
      await prefs.setInt('household_created', _created!.millisecondsSinceEpoch);

      // Update all inventory items to have the new household ID
      await updateInventoryHouseholdIds();

      Log.i('ObjectBoxHouseholdDatabase: User successfully joined household $householdId');
    } catch (e) {
      // Revert to old household ID if there was an error
      _householdId = oldHouseholdId;
      Log.e('ObjectBoxHouseholdDatabase: Failed to join household', e.toString());
      throw Exception('Failed to join household: $e');
    }
  }

  @override
  void leave() {
    // Remove all household members
    box.removeAll();

    // Create a new household
    _createNewHousehold();

    // Copy inventory items from old household to new one
    if (_inventoryDb != null) {
      Log.i('ObjectBoxHouseholdDatabase: Updating inventory items for new household');

      // In ObjectBox, we don't need to copy items - we just update their householdId
      // This will be handled by the updateInventoryHouseholdIds method
      updateInventoryHouseholdIds();
    }
  }

  /// Sets the inventory database reference
  void setInventoryDatabase(InventoryDatabase db) {
    _inventoryDb = db;
  }

  /// Sets the item database reference
  void setItemDatabase(ItemDatabase db) {}

  @override
  Future<void> updateInventoryHouseholdIds() async {
    if (_inventoryDb == null) {
      Log.w('ObjectBoxHouseholdDatabase: Inventory database not set, cannot update household IDs');
      return;
    }

    try {
      // Get all inventory items
      final items = _inventoryDb!.all();

      // Update each item with the new household ID
      for (final item in items) {
        if (item.householdId != _householdId) {
          final updatedItem = item.copyWith(householdId: _householdId!);
          _inventoryDb!.put(updatedItem);
        }
      }

      Log.i('ObjectBoxHouseholdDatabase: Successfully updated inventory household IDs');
    } catch (e) {
      Log.e('ObjectBoxHouseholdDatabase: Failed to update inventory household IDs', e.toString());
      throw Exception('Failed to update inventory household IDs: $e');
    }
  }

  void _createNewHousehold() {
    _householdId = const Uuid().v4();
    _created = DateTime.now();
    prefs.setString('household_id', _householdId!);
    prefs.setInt('household_created', _created!.millisecondsSinceEpoch);
  }

  void _loadHousehold() {
    _householdId = prefs.getString('household_id')!;
    _created = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('household_created')!);
  }
}
