// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/manufacturer.dart';

part 'manufacturer.hive.g.dart';

@HiveType(typeId: 0)
class HiveManufacturer extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late String website;
  @HiveField(4)
  late String uid;
  @HiveField(5)
  late String parentName;
  @HiveField(6)
  late String parentUid;
  HiveManufacturer();
  HiveManufacturer.from(Manufacturer original) {
    created = original.created;
    updated = original.updated;
    name = original.name;
    website = original.website;
    uid = original.uid;
    parentName = original.parentName;
    parentUid = original.parentUid;
  }
  Manufacturer convert() {
    return Manufacturer(
        created: created,
        name: name,
        parentName: parentName,
        parentUid: parentUid,
        uid: uid,
        updated: updated,
        website: website);
  }
}
