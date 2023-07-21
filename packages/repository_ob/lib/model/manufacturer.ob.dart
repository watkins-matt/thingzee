import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/manufacturer.dart';
@Entity()
class ObjectBoxManufacturer {
  late String name;
  late String website;
  late String muid;
  late String parentName;
  late String parentMuid;
  @Id()
  int objectBoxId = 0;
  ObjectBoxManufacturer();
  ObjectBoxManufacturer.from(Manufacturer original) {
    name = original.name;
    website = original.website;
    muid = original.muid;
    parentName = original.parentName;
    parentMuid = original.parentMuid;
  }
  Manufacturer toManufacturer() {
    return Manufacturer()
      ..name = name
      ..website = website
      ..muid = muid
      ..parentName = parentName
      ..parentMuid = parentMuid
    ;
  }
}
