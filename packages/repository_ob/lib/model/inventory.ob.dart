import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:quiver/core.dart';
import 'package:repository/ml/ml_history.dart';
import 'package:repository/model/inventory.dart';
@Entity()
class ObjectBoxInventory {
  late double amount;
  late int unitCount;
  late Optional<DateTime> lastUpdate;
  List<DateTime> expirationDates = [];
  List<String> locations = [];
  @Transient()
  late MLHistory history;
  late bool restock;
  @Unique()
  late String upc;
  late String iuid;
  late double units;
  @Id()
  int id = 0;
  ObjectBoxInventory();
  ObjectBoxInventory.from(Inventory original) {
    amount = original.amount;
    unitCount = original.unitCount;
    lastUpdate = original.lastUpdate;
    expirationDates = original.expirationDates;
    locations = original.locations;
    history = original.history;
    restock = original.restock;
    upc = original.upc;
    iuid = original.iuid;
    units = original.units;
  }
  Inventory toInventory() {
    return Inventory()
      ..amount = amount
      ..unitCount = unitCount
      ..lastUpdate = lastUpdate
      ..expirationDates = expirationDates
      ..locations = locations
      ..history = history
      ..restock = restock
      ..upc = upc
      ..iuid = iuid
      ..units = units
    ;
  }
}
