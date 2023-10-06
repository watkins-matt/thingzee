import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/location.dart';

part 'location.hive.g.dart';
@HiveType(typeId: 6)
class HiveLocation extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late double? quantity;
  @HiveField(3)
  late DateTime? created;
  @HiveField(4)
  late DateTime? updated;
  HiveLocation();
  HiveLocation.from(Location original) {
    upc = original.upc;
    name = original.name;
    quantity = original.quantity;
    created = original.created;
    updated = original.updated;
  }
  Location toLocation() {
    return Location(
      upc: upc,
      name: name,
      quantity: quantity,
      created: created,
      updated: updated
    );
  }
}
