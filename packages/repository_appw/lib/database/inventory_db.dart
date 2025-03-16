// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteInventoryDatabase extends InventoryDatabase
    with AppwriteSynchronizable<Inventory>, AppwriteDatabase<Inventory> {
  static const String tag = 'AppwriteInventoryDatabase';

  String _householdId;

  AppwriteInventoryDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
    this._householdId,
  ) : super() {
    constructDatabase(tag, database, databaseId, collectionId);
    constructSynchronizable(tag, prefs, onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });
  }

  /// Gets the current household ID
  String get householdId => _householdId;

  @override
  Inventory deserialize(Map<String, dynamic> json) => Inventory.fromJson(json);

  @override
  List<Inventory> outs() => values.where((inv) => inv.amount <= 0 && inv.restock).toList();

  @override
  void put(Inventory item, {List<String>? permissions}) {
    // Ensure the inventory item has the current household ID
    if (item.householdId != _householdId) {
      item = item.copyWith(householdId: _householdId);
    }

    // Add household team permissions to allow sharing inventory
    final teamPermissions = [
      Permission.read(Role.team(_householdId)),
      Permission.update(Role.team(_householdId)),
    ];

    // Combine with any existing permissions
    final allPermissions =
        permissions != null ? [...permissions, ...teamPermissions] : teamPermissions;

    // Call the parent put method with the updated permissions
    super.put(item, permissions: allPermissions);
  }

  @override
  Map<String, dynamic> serialize(Inventory inventory) {
    var json = inventory.toJson();
    json['userId'] = userId;
    json.remove('history');
    json.remove('units');

    return json;
  }

  /// Updates all inventory items to have the current household ID
  Future<void> updateHouseholdIds(String newHouseholdId) async {
    if (!online) {
      throw Exception('Cannot update inventory household IDs while offline.');
    }

    // Update the household ID
    _householdId = newHouseholdId;

    // Update all inventory items in memory
    final updatedItems = <Inventory>[];
    for (final item in values) {
      if (item.householdId != newHouseholdId) {
        updatedItems.add(item.copyWith(householdId: newHouseholdId));
      }
    }

    // Save the updated items
    for (final item in updatedItems) {
      put(item);
    }
  }
}
