import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/location.dart';

@Entity()
class ObjectBoxLocation {
  late String upc;
  late String location;
  late double? quantity;
  late DateTime? created;
  late DateTime? updated;
  @Id()
  int objectBoxId = 0;
  ObjectBoxLocation();
  ObjectBoxLocation.from(Location original) {
    upc = original.upc;
    location = original.name;
    quantity = original.quantity;
    created = original.created;
    updated = original.updated;
  }
  Location toLocation() {
    return Location(
        upc: upc, name: location, quantity: quantity, created: created, updated: updated);
  }
}
