import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/manufacturer.dart';
@HiveType(typeId: 0)
class HiveManufacturer extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late String website;
  @HiveField(2)
  late String muid;
  @HiveField(3)
  late String parentName;
  @HiveField(4)
  late String parentMuid;
  HiveManufacturer(Manufacturer original) {
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
