// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/location.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxLocation extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
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
  Location toLocation() {
    return Location(
        created: created,
        updated: updated,
        upc: upc,
        name: name,
        quantity: quantity);
  }
}
