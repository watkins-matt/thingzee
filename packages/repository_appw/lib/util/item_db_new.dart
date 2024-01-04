import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Log, Preferences;
import 'package:collection/collection.dart';
import 'package:log/log.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';
import 'package:repository/util/hash.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteItemDatabase extends ItemDatabase
    with AppwriteSynchronizable<Item>, AppwriteDatabase<Item> {
  AppwriteItemDatabase(
    Preferences prefs,
    Databases database,
    String databaseId,
    String collectionId,
  ) : super() {
    constructSynchronizable('AppwriteItemDatabase', prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
    constructDatabase(database, databaseId, collectionId);
  }

  @override
  List<Item> documentsToList(DocumentList documents) {
    return documents.documents
        .map((doc) {
          try {
            return Item.fromJson(doc.data);
          } catch (e) {
            Log.w('Failed to deserialize Item from upc: ${doc.data["upc"]}', e);
            return null;
          }
        })
        .whereNotNull()
        .toList();
  }

  @override
  List<Item> filter(Filter filter) {
    return values
        .where((item) =>
            (filter.consumable && item.consumable) || (filter.nonConsumable && !item.consumable))
        .toList();
  }

  @override
  List<Item> getChanges(DateTime since) {
    return values
        .where((item) => item.lastUpdate != null && item.lastUpdate!.isAfter(since))
        .toList();
  }

  @override
  String getKey(Item item) => item.upc;

  @override
  Item merge(Item existingItem, Item newItem) => existingItem.merge(newItem);

  @override
  List<Item> search(String query) {
    return values.where((item) => item.name.contains(query)).toList();
  }

  @override
  Map<String, dynamic> serializeItem(Item item) {
    var json = item.toJson();
    json['userId'] = userId;
    return json;
  }

  @override
  String uniqueDocumentId(String id) {
    if (userId.isEmpty) {
      throw Exception('AppwriteItemDB: User ID is empty, cannot generate unique document ID.');
    }

    return hashBarcode(userId, id);
  }
}
