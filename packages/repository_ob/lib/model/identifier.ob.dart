

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/identifier.dart';

@Entity()
class ObjectBoxItemIdentifier {
  late String type;
  late String value;
  late String uid;
  @Id()
  int objectBoxId = 0;
  ObjectBoxItemIdentifier();
  ObjectBoxItemIdentifier.from(ItemIdentifier original) {
    type = original.type;
    value = original.value;
    uid = original.uid;
  }
  ItemIdentifier toItemIdentifier() {
    return ItemIdentifier(
        type: type,
        value: value,
        uid: uid);
  }
}
