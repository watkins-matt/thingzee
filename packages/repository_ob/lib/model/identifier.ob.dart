// ignore_for_file: annotate_overrides

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxItemIdentifier extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;
  late String type;
  late String value;
  late String uid;
  ObjectBoxItemIdentifier();
  ObjectBoxItemIdentifier.from(Identifier original) {
    created = original.created;
    updated = original.updated;
    type = original.type;
    value = original.value;
    uid = original.uid;
  }
  Identifier toItemIdentifier() {
    return Identifier(created: created, updated: updated, type: type, value: value, uid: uid);
  }
}
