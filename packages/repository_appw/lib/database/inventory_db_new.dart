import 'package:appwrite/appwrite.dart';
import 'package:repository/database/inventory_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteInventoryDatabase extends InventoryDatabase
    with AppwriteSynchronizable<Inventory>, AppwriteDatabase<Inventory> {
  static const String TAG = 'AppwriteInventoryDatabase';

  AppwriteInventoryDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
  ) : super() {
    constructSynchronizable(TAG, prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
    constructDatabase(TAG, database, databaseId, collectionId);
  }

  @override
  Inventory deserialize(Map<String, dynamic> json) => Inventory.fromJson(json);

  @override
  String getKey(Inventory item) => item.upc;

  @override
  DateTime? getUpdated(Inventory item) => item.lastUpdate;

  @override
  Inventory merge(Inventory existingItem, Inventory newItem) => existingItem.merge(newItem);

  @override
  List<Inventory> outs() => values.where((inv) => inv.amount <= 0 && inv.restock).toList();

  @override
  Map<String, dynamic> serialize(Inventory item) {
    var json = item.toJson();
    json['userId'] = userId;
    json.remove('history');
    json.remove('units');

    return json;
  }
}
