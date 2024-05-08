// ignore_for_file: annotate_overrides

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/manufacturer.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxManufacturer extends ObjectBoxModel<Manufacturer> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String name;
  late String website;
  late String uid;
  late String parentName;
  late String parentUid;
  ObjectBoxManufacturer();
  ObjectBoxManufacturer.from(Manufacturer original) {
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
        updated: updated,
        name: name,
        website: website,
        uid: uid,
        parentName: parentName,
        parentUid: parentUid);
  }
}
