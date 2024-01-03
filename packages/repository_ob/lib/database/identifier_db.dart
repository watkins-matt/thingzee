import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/model/identifier.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxIdentifierDatabase extends IdentifierDatabase {
  late final Box<ObjectBoxItemIdentifier> box;

  ObjectBoxIdentifierDatabase(Store store) {
    box = store.box<ObjectBoxItemIdentifier>();
  }

  @override
  List<ItemIdentifier> all() {
    final all = box.getAll();
    return all.map((objBoxIdentifier) => objBoxIdentifier.toItemIdentifier()).toList();
  }

  @override
  void delete(ItemIdentifier identifier) {
    final query = box.query(ObjectBoxItemIdentifier_.value.equals(identifier.value)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  String get(String identifier) {
    final query = box.query(ObjectBoxItemIdentifier_.value.equals(identifier)).build();
    final result = query.findFirst();
    query.close();

    return result?.toItemIdentifier().uid ?? '';
  }

  @override
  List<ItemIdentifier> getAll(List<String> identifiers) {
    final query = box.query(ObjectBoxItemIdentifier_.value.oneOf(identifiers)).build();
    final results = query.find();
    query.close();

    return results.map((objBoxIdentifier) => objBoxIdentifier.toItemIdentifier()).toList();
  }

  @override
  List<ItemIdentifier> getChanges(DateTime since) {
    final query = box
        .query(ObjectBoxItemIdentifier_.updated.greaterThan(since.millisecondsSinceEpoch))
        .build();
    final results = query.find();
    query.close();

    return results.map((objBoxIdentifier) => objBoxIdentifier.toItemIdentifier()).toList();
  }

  @override
  Map<String, ItemIdentifier> map() {
    final allIdentifiers = all();
    return {for (final identifier in allIdentifiers) identifier.value: identifier};
  }

  @override
  void put(ItemIdentifier identifier) {
    final identifierOb = ObjectBoxItemIdentifier.from(identifier);

    final query = box.query(ObjectBoxItemIdentifier_.value.equals(identifier.value)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && identifierOb.objectBoxId != exists.objectBoxId) {
      identifierOb.objectBoxId = exists.objectBoxId;
    }

    box.put(identifierOb);
  }
}
