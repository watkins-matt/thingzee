// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxItemIdentifier extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
  late String type;
  late String value;
  late String uid;
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
