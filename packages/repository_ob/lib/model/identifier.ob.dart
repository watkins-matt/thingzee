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
  late String value;
  late String uid;
  ObjectBoxIdentifier();
  ObjectBoxIdentifier.from(Identifier original) {
    created = original.created;
    updated = original.updated;
    type = original.type;
    value = original.value;
    uid = original.uid;
  }
  Identifier convert() {
    return Identifier(created: created, updated: updated, type: type, value: value, uid: uid);
  }
}
