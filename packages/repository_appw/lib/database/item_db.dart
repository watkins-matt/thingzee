import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteItemDatabase extends ItemDatabase
    with AppwriteSynchronizable<Item>, AppwriteDatabase<Item> {
  static const String tag = 'AppwriteItemDatabase';
  String _householdId;

  AppwriteItemDatabase(
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
  Item deserialize(Map<String, dynamic> json) => Item.fromJson(json);

  @override
  List<Item> filter(Filter filter) {
    return values
        .where((item) =>
            (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
        .toList();
  }

  @override
  void put(Item item, {List<String>? permissions}) {
    // Add household team permissions to allow sharing items
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
  List<Item> search(String string) {
    return values.where((item) => item.name.contains(string)).toList();
  }

  @override
  Map<String, dynamic> serialize(Item item) {
    var json = item.toJson();
    json['userId'] = userId;
    return json;
  }

  /// Updates the household ID
  void updateHouseholdId(String newHouseholdId) {
    _householdId = newHouseholdId;
  }

  /// Updates all items to have the current household ID permissions
  Future<void> updateHouseholdPermissions() async {
    if (!online) {
      throw Exception('Cannot update item household permissions while offline.');
    }

    // Update all items in memory with new permissions
    for (final item in values) {
      // Re-put the item to update its permissions
      put(item);
    }

    Log.i('$tag: Successfully updated item permissions for household $_householdId');
  }
}
