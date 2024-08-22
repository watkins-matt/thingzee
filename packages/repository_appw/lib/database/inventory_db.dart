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

  AppwriteInventoryDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
  ) : super() {
    constructDatabase(tag, database, databaseId, collectionId);
    constructSynchronizable(tag, prefs, onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });
  }

  @override
  Inventory deserialize(Map<String, dynamic> json) => Inventory.fromJson(json);

  @override
  List<Inventory> outs() => values.where((inv) => inv.amount <= 0 && inv.restock).toList();

  @override
  Map<String, dynamic> serialize(Inventory inventory) {
    var json = inventory.toJson();
    json['userId'] = userId;
    json.remove('history');
    json.remove('units');

    return json;
  }
}
