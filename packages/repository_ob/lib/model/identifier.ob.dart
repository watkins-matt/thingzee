import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';

@Entity()
class ObjectBoxItemIdentifier {
  late DateTime? created;
  late DateTime? updated;
  late String type;
  late String value;
  late String uid;
  @Id()
  int objectBoxId = 0;
  ObjectBoxItemIdentifier();
  ObjectBoxItemIdentifier.from(ItemIdentifier original) {
    created = original.created;
    updated = original.updated;
    type = original.type;
    value = original.value;
    uid = original.uid;
  }
  ItemIdentifier toItemIdentifier() {
    return ItemIdentifier(
        created: created,
        updated: updated,
        type: type,
        value: value,
        uid: uid);
  }
}
