import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/identifier.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

class ObjectBoxIdentifierDatabase extends IdentifierDatabase
    with ObjectBoxDatabase<Identifier, ObjectBoxItemIdentifier> {
  ObjectBoxIdentifierDatabase(Store store) {
    constructDb(store);
  }

  @override
  Condition<ObjectBoxItemIdentifier> buildIdCondition(String id) {
    return ObjectBoxItemIdentifier_.value.equals(id);
  }

  @override
  Condition<ObjectBoxItemIdentifier> buildIdsCondition(List<String> ids) {
    return ObjectBoxItemIdentifier_.value.oneOf(ids);
  }

  @override
  Condition<ObjectBoxItemIdentifier> buildSinceCondition(DateTime since) {
    return ObjectBoxItemIdentifier_.updated.greaterThan(since.millisecondsSinceEpoch);
  }

  @override
  ObjectBoxItemIdentifier fromModel(Identifier model) => ObjectBoxItemIdentifier.from(model);

  @override
  Identifier toModel(ObjectBoxItemIdentifier objectBoxEntity) => objectBoxEntity.toItemIdentifier();
}
