// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/place.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxPlace extends ObjectBoxModel<Place> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String phoneNumber;
  late String name;
  late String city;
  late String state;
  late String zipcode;
  ObjectBoxPlace();
  ObjectBoxPlace.from(Place original) {
    created = original.created;
    updated = original.updated;
    phoneNumber = original.phoneNumber;
    name = original.name;
    city = original.city;
    state = original.state;
    zipcode = original.zipcode;
  }
  Place convert() {
    return Place(
        created: created,
        updated: updated,
        phoneNumber: phoneNumber,
        name: name,
        city: city,
        state: state,
        zipcode: zipcode);
  }
}
