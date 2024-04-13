import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/identifier.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxIdentifierDatabase extends IdentifierDatabase
    with ObjectBoxDatabase<Identifier, ObjectBoxIdentifier> {
  ObjectBoxIdentifierDatabase(Store store) {
    init(store, ObjectBoxIdentifier.from, null, ObjectBoxIdentifier_.updated);
  }

  @override
  Condition<ObjectBoxIdentifier> buildIdCondition(String id) {
    // Split the id on the first -
    final parts = id.split('-');
    final type = parts[0];
    final value = parts[1];

    return ObjectBoxIdentifier_.type.equals(type).and(ObjectBoxIdentifier_.value.equals(value));
  }

  @override
  Condition<ObjectBoxIdentifier> buildIdsCondition(List<String> ids) {
    final parts = ids.map((e) => e.split('-')).toList();
    final types = parts.map((e) => e[0]).toList();
    final values = parts.map((e) => e[1]).toList();

    return ObjectBoxIdentifier_.type.oneOf(types).and(ObjectBoxIdentifier_.value.oneOf(values));
  }

  @override
  List<Identifier> getAllForUid(String uid) {
    final query = box.query(ObjectBoxIdentifier_.uid.equals(uid)).build();
    return query.find().map((e) => e.convert()).toList();
  }

  @override
  List<Identifier> getAllForUpc(String upc) {
    final uid = uidFromUPC(upc);

    if (uid != null) {
      final query = box.query(ObjectBoxIdentifier_.uid.equals(uid)).build();
      return query.find().map((e) => e.convert()).toList();
    }

    return [];
  }

  @override
  String? uidFromUPC(String upc) {
    final query = box
        .query(ObjectBoxIdentifier_.type.equals('UPC').and(ObjectBoxIdentifier_.value.equals(upc)))
        .build();
    final identifier = query.findFirst();
    return identifier?.uid;
  }
}
