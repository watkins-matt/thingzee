// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/place.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxPlace extends ObjectBoxModel<Place> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late String city;
  late String name;
  late String phoneNumber;
  late String state;
  late String zipcode;
  ObjectBoxPlace();
  ObjectBoxPlace.from(Place original) {
    city = original.city;
    created = original.created;
    name = original.name;
    phoneNumber = original.phoneNumber;
    state = original.state;
    updated = original.updated;
    zipcode = original.zipcode;
  }
  Place convert() {
    return Place(
        city: city,
        created: created,
        name: name,
        phoneNumber: phoneNumber,
        state: state,
        updated: updated,
        zipcode: zipcode);
  }
}
