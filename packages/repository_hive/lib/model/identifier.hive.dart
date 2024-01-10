import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/identifier.dart';

part 'identifier.hive.g.dart';

@HiveType(typeId: 0)
class HiveItemIdentifier extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String type;
  @HiveField(3)
  late String value;
  @HiveField(4)
  late String uid;
  HiveItemIdentifier();
  HiveItemIdentifier.from(ItemIdentifier original) {
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
