// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/place.dart';

part 'place.hive.g.dart';

@HiveType(typeId: 0)
class HivePlace extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String phoneNumber;
  @HiveField(3)
  late String name;
  @HiveField(4)
  late String city;
  @HiveField(5)
  late String state;
  @HiveField(6)
  late String zipcode;
  HivePlace();
  HivePlace.from(Place original) {
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
