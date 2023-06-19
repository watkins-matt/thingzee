import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:quiver/core.dart';
import 'package:repository/database/item_database.dart';
import 'package:repository/model/filter.dart';
import 'package:repository/model/item.dart';

class AppwriteItemDatabase extends ItemDatabase {
  final Databases _database;
  final String databaseId;
  final String collectionId;
  // ignore: prefer_final_fields
  List<Item> _items = [];

  AppwriteItemDatabase(this._database, this.databaseId, this.collectionId) {
    refresh();
  }

  // ignore: unused_element
  List<Item> _documentsToList(DocumentList documentList) {
    throw UnimplementedError();
  }

  Future<void> refresh() async {
    try {
      // ignore: unused_local_variable
      DocumentList response =
          await _database.listDocuments(databaseId: databaseId, collectionId: collectionId);
    } on AppwriteException catch (e) {
      print(e);
    }
  }

  @override
  List<Item> all() {
    if (_items.isEmpty) {
      refresh();
    }

    return _items;
  }

  @override
  void delete(Item item) {
    throw UnimplementedError();
  }

  @override
  void deleteAll() {
    throw UnimplementedError();
  }

  @override
  List<Item> filter(Filter filter) {
    throw UnimplementedError();
  }

  @override
  Optional<Item> get(String upc) {
    throw UnimplementedError();
  }

  @override
  List<Item> getAll(List<String> upcs) {
    throw UnimplementedError();
  }

  @override
  void put(Item item) {
    throw UnimplementedError();
  }

  @override
  List<Item> search(String string) {
    throw UnimplementedError();
  }
}
