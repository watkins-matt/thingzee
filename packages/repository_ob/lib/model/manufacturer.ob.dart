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
  late String parentName;
  late String parentUid;
  late String uid;
  late String website;
  ObjectBoxManufacturer();
  ObjectBoxManufacturer.from(Manufacturer original) {
    created = original.created;
    name = original.name;
    parentName = original.parentName;
    parentUid = original.parentUid;
    uid = original.uid;
    updated = original.updated;
    website = original.website;
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
