// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/location.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxLocation extends ObjectBoxModel<Location> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late double? quantity;
  late String name;
  late String upc;
  ObjectBoxLocation();
  ObjectBoxLocation.from(Location original) {
    created = original.created;
    name = original.name;
    quantity = original.quantity;
    upc = original.upc;
    updated = original.updated;
  }
  Location convert() {
    return Location(
        created: created,
        name: name,
        quantity: quantity,
        upc: upc,
        updated: updated);
  }
}
