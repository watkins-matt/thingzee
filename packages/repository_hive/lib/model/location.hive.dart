import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/location.dart';

part 'location.hive.g.dart';
@HiveType(typeId: 6)
class HiveLocation extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late String location;
  @HiveField(2)
  late double? quantity;
  @HiveField(3)
  late DateTime? created;
  @HiveField(4)
  late DateTime? updated;
  HiveLocation();
  HiveLocation.from(Location original) {
    upc = original.upc;
    location = original.location;
    quantity = original.quantity;
    created = original.created;
    updated = original.updated;
  }
  Location toLocation() {
    return Location(
      upc: upc,
      location: location,
      quantity: quantity,
      created: created,
      updated: updated
    );
  }
}