import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_appw/util/appwrite_database.dart';
import 'package:repository_appw/util/synchronizable.dart';

class AppwriteIdentifierDatabase extends IdentifierDatabase
    with AppwriteSynchronizable<ItemIdentifier>, AppwriteDatabase<ItemIdentifier> {
  static const String TAG = 'AppwriteIdentifierDatabase';

  @override
  ItemIdentifier? deserialize(Map<String, dynamic> json) => ItemIdentifier.fromJson(json);

  @override
  String getKey(ItemIdentifier item) => '${item.type}-${item.value}}';

  @override
  DateTime? getUpdated(ItemIdentifier item) => item.updated;

  @override
  ItemIdentifier merge(ItemIdentifier existingItem, ItemIdentifier newItem) =>
      existingItem.merge(newItem);

  @override
  Map<String, dynamic> serialize(ItemIdentifier item) => item.toJson();
}
