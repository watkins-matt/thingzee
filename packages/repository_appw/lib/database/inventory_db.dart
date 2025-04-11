// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
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
    constructSynchronizable(tag, prefs,
        onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });
  }

  /// Gets the current household ID
  String get householdId => _householdId;

  @override
  Inventory deserialize(Map<String, dynamic> json) => Inventory.fromJson(json);

  /// Overrides the default getDocuments method to include household filtering
  @override
  Future<appwrite_models.DocumentList> getDocuments(List<String> queries) =>
      super.getDocuments(queries);

  /// Overrides the default getModifiedDocuments to include household data
  @override
  Future<appwrite_models.DocumentList> getModifiedDocuments(
      DateTime? lastSyncTime) async {
    // Get documents updated since the last sync that the user has permission to read.
    // Appwrite automatically handles permission filtering.
    final timeQuery = Query.greaterThan(
        '\$updatedAt', // Use Appwrite's internal timestamp field
        (lastSyncTime?.millisecondsSinceEpoch ?? 0) ~/
            1000 // Appwrite uses seconds epoch
        );

    final queries = [
      timeQuery,
    ];

    // Call the base getDocuments implementation with the time query.
    // It will return documents matching the query that the user can access.
    return await super.getDocuments(queries);
  }

  @override
  List<Inventory> outs() =>
      values.where((inv) => inv.amount <= 0 && inv.restock).toList();

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
    final allPermissions = permissions != null
        ? [...permissions, ...teamPermissions]
        : teamPermissions;

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
