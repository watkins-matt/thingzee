import 'package:repository/model/identifier.dart';

abstract class IdentifierDatabase {
  List<ItemIdentifier> all();
  void delete(ItemIdentifier identifier);
  void deleteAll();
  String get(String identifier);
  List<ItemIdentifier> getAll(List<String> identifiers);
  List<ItemIdentifier> getChanges(DateTime since);
  Map<String, ItemIdentifier> map();
  void put(ItemIdentifier identifier);
}
