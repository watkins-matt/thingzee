import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/identifier.dart';

part 'identifier.hive.g.dart';

@HiveType(typeId: 0)
class HiveItemIdentifier extends HiveObject {
  @HiveField(0)
  late String type;
  @HiveField(1)
  late String value;
  @HiveField(2)
  late String uid;
  @HiveField(3)
  late DateTime? created;
  @HiveField(4)
  late DateTime? updated;
  HiveItemIdentifier();
  HiveItemIdentifier.from(ItemIdentifier original) {
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
