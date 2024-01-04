import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:log/log.dart';
import 'package:repository/database/history_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/ml/history.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteHistoryDatabase extends HistoryDatabase
    with AppwriteSynchronizable<History>, AppwriteDatabase<History> {
  static const String TAG = 'AppwriteHistoryDatabase';

  AppwriteHistoryDatabase(
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
  History? deserialize(Map<String, dynamic> json) {
    try {
      return History.fromJson(jsonDecode(json['json']));
    } catch (e) {
      Log.w('$TAG: Failed to deserialize History object for upc ${json["upc"]}. Error: $e');
      return null;
    }
  }

  @override
  String getKey(History item) => item.upc;

  @override
  DateTime? getUpdated(History item) => item.lastTimestamp;

  @override
  History merge(History existingItem, History newItem) => existingItem.merge(newItem);

  @override
  Map<String, dynamic> serialize(History item) {
    Map<String, dynamic> serialized = {
      'userId': userId,
      'upc': item.upc,
      'json': jsonEncode(item.toJson())
    };

    return serialized;
  }
}
