import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/identifier.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxIdentifierDatabase extends IdentifierDatabase
    with ObjectBoxDatabase<Identifier, ObjectBoxIdentifier> {
  ObjectBoxIdentifierDatabase(Store store) {
    constructDb(store);
  }

  @override
  Condition<ObjectBoxIdentifier> buildIdCondition(String id) {
    return ObjectBoxIdentifier_.value.equals(id);
  }

  @override
  Condition<ObjectBoxIdentifier> buildIdsCondition(List<String> ids) {
    return ObjectBoxIdentifier_.value.oneOf(ids);
  }

  @override
  Condition<ObjectBoxIdentifier> buildSinceCondition(DateTime since) {
    return ObjectBoxIdentifier_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxIdentifier fromModel(Identifier model) => ObjectBoxIdentifier.from(model);

  @override
  Identifier toModel(ObjectBoxIdentifier objectBoxEntity) => objectBoxEntity.toIdentifier();
}
