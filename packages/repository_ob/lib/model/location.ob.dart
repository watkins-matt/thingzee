import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/location.dart';

@Entity()
class ObjectBoxLocation {
  late String upc;
  late String name;
  late double? quantity;
  late DateTime? created;
  late DateTime? updated;
  @Id()
  int objectBoxId = 0;
  ObjectBoxLocation();
  ObjectBoxLocation.from(Location original) {
    upc = original.upc;
    name = original.name;
    quantity = original.quantity;
    created = original.created;
    updated = original.updated;
  }
  Location toLocation() {
    return Location(upc: upc, name: name, quantity: quantity, created: created, updated: updated);
  }
}
