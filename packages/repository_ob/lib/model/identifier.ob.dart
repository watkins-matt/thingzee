// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxIdentifier extends ObjectBoxModel<Identifier> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String type;
  late String uid;
  late String value;
  ObjectBoxIdentifier();
  ObjectBoxIdentifier.from(Identifier original) {
    created = original.created;
    type = original.type;
    uid = original.uid;
    updated = original.updated;
    value = original.value;
  }
  Identifier convert() {
    return Identifier(
        created: created,
        type: type,
        uid: uid,
        updated: updated,
        value: value);
  }
}
