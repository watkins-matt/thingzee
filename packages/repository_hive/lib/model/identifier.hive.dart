// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/identifier.dart';

part 'identifier.hive.g.dart';

@HiveType(typeId: 0)
class HiveIdentifier extends HiveObject {
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
  HiveIdentifier();
  HiveIdentifier.from(Identifier original) {
    created = original.created;
    updated = original.updated;
    type = original.type;
    value = original.value;
    uid = original.uid;
  }
  Identifier toIdentifier() {
    return Identifier(
        created: created,
        updated: updated,
        type: type,
        value: value,
        uid: uid);
  }
}
