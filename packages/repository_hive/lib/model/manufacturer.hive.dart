import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/manufacturer.dart';

part 'manufacturer.hive.g.dart';

@HiveType(typeId: 3)
class HiveManufacturer extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late String website;
  @HiveField(2)
  late String uid;
  @HiveField(3)
  late String parentName;
  @HiveField(4)
  late String parentUid;
  HiveManufacturer();
  HiveManufacturer.from(Manufacturer original) {
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
