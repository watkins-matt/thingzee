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
  late String upc;
  late String name;
  late double? quantity;
  ObjectBoxLocation();
  ObjectBoxLocation.from(Location original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    name = original.name;
    quantity = original.quantity;
  }
  Location convert() {
    return Location(created: created, updated: updated, upc: upc, name: name, quantity: quantity);
  }
}
