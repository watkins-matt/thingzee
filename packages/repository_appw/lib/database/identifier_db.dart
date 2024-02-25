// ignore_for_file: avoid_renaming_method_parameters

import 'package:appwrite/appwrite.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteIdentifierDatabase extends IdentifierDatabase
    with AppwriteSynchronizable<Identifier>, AppwriteDatabase<Identifier> {
  static const String TAG = 'AppwriteIdentifierDatabase';

  AppwriteIdentifierDatabase(
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
  Identifier? deserialize(Map<String, dynamic> json) => Identifier.fromJson(json);

  @override
  List<Identifier> getAllForUpc(String upc) =>
      values.where((identifier) => identifier.uid == upc).toList();
}
