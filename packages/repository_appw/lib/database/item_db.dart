import 'package:appwrite/appwrite.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteItemDatabase extends ItemDatabase
    with AppwriteSynchronizable<Item>, AppwriteDatabase<Item> {
  static const String tag = 'AppwriteItemDatabase';

  AppwriteItemDatabase(
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
  Item deserialize(Map<String, dynamic> json) => Item.fromJson(json);

  @override
  List<Item> filter(Filter filter) {
    return values
        .where((item) =>
            (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
        .toList();
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
}
