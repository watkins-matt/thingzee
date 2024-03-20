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
    constructSynchronizable(TAG, prefs, onConnectivityChange: (bool online) async {
      if (online) {
        await taskQueue.runUntilComplete();
      }
    });
  }

  @override
  Identifier? deserialize(Map<String, dynamic> json) => Identifier.fromJson(json);

  @override
  List<Identifier> getAllForUid(String uid) {
    return values.where((identifier) => identifier.uid == uid).toList();
  }

  @override
  List<Identifier> getAllForUpc(String upc) {
    final uid = uidFromUPC(upc);

    if (uid == null) {
      return [];
    }

    return values.where((identifier) => identifier.uid == uid).toList();
  }

  @override
  Map<String, dynamic> serialize(Identifier identifier) {
    var json = identifier.toJson();
    json['userId'] = userId;
    return json;
  }

  @override
  String? uidFromUPC(String upc) => values
      .where((identifier) => identifier.type == IdentifierType.upc && identifier.value == upc)
      .map((e) => e.uid)
      .firstOrNull;
}
