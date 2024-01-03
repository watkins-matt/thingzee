import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';

@Entity()
class ObjectBoxItemIdentifier {
  late String type;
  late String value;
  late String uid;
  late DateTime? created;
  late DateTime? updated;
  @Id()
  int objectBoxId = 0;
  ObjectBoxItemIdentifier();
  ObjectBoxItemIdentifier.from(ItemIdentifier original) {
    type = original.type;
    value = original.value;
    uid = original.uid;
    created = original.created;
    updated = original.updated;
  }
  ItemIdentifier toItemIdentifier() {
    return ItemIdentifier(
        type: type,
        value: value,
        uid: uid,
        created: created,
        updated: updated);
  }
}
