

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/manufacturer.dart';

@Entity()
class ObjectBoxManufacturer {
  late String name;
  late String website;
  late String uid;
  late String parentName;
  late String parentUid;
  @Id()
  int objectBoxId = 0;
  ObjectBoxManufacturer();
  ObjectBoxManufacturer.from(Manufacturer original) {
    name = original.name;
    website = original.website;
    uid = original.uid;
    parentName = original.parentName;
    parentUid = original.parentUid;
  }
  Manufacturer toManufacturer() {
    return Manufacturer()
      ..name = name
      ..website = website
      ..uid = uid
      ..parentName = parentName
      ..parentUid = parentUid;
  }
}
