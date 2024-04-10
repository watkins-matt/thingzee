// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/location.dart';

part 'location.hive.g.dart';

@HiveType(typeId: 0)
class HiveLocation extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late String name;
  @HiveField(4)
  late double? quantity;
  HiveLocation();
  HiveLocation.from(Location original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    name = original.name;
    quantity = original.quantity;
  }
  Location convert() {
    return Location(
        created: created,
        updated: updated,
        upc: upc,
        name: name,
        quantity: quantity);
  }
}
