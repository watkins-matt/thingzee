// ignore_for_file: avoid_renaming_method_parameters

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
    constructDatabase(TAG, database, databaseId, collectionId);
    constructSynchronizable(TAG, prefs, onConnectivityChange: () async {
      await taskQueue.runUntilComplete();
    });
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
  Map<String, dynamic> serialize(History history) {
    Map<String, dynamic> serialized = {
      'userId': userId,
      'upc': history.upc,
      'created': history.created?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'updated': history.updated?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'json': jsonEncode(history.toJson())
    };

    return serialized;
  }
}
