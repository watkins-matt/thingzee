import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';
@Entity()
class ObjectBoxInventory {
  late double amount;
  late int unitCount;
  late DateTime? lastUpdate;
  List<DateTime> expirationDates = [];
  List<String> locations = [];
  @Transient()
  History history = History();
  late bool restock;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  late String uid;
  late double units;
  @Id()
  int objectBoxId = 0;
  ObjectBoxInventory();
  ObjectBoxInventory.from(Inventory original) {
    // Ensure history is in a consistent state
    history.upc = original.upc;
    amount = original.amount;
    unitCount = original.unitCount;
    lastUpdate = original.lastUpdate;
    expirationDates = original.expirationDates;
    locations = original.locations;
    history = original.history;
    restock = original.restock;
    upc = original.upc;
    uid = original.uid;
    units = original.units;
  }
  Inventory toInventory() {
    // Ensure history is in a consistent state
    history.upc = upc;
    return Inventory()
      ..amount = amount
      ..unitCount = unitCount
      ..lastUpdate = lastUpdate
      ..expirationDates = expirationDates
      ..locations = locations
      ..history = history
      ..restock = restock
      ..upc = upc
      ..uid = uid
      ..units = units
    ;
  }
int get dbLastUpdate {
  return lastUpdate != null ? lastUpdate!.millisecondsSinceEpoch : 0;
}

set dbLastUpdate(int value) {
  lastUpdate = value != 0
      ? DateTime.fromMillisecondsSinceEpoch(value)
      : null;
}

List<String> get dbExpirationDates {
  List<String> dates = [];
  for (final exp in expirationDates) {
    dates.add(exp.millisecondsSinceEpoch.toString());
  }

  return dates;
}

set dbExpirationDates(List<String> dates) {
  expirationDates.clear();

  for (final date in dates) {
    int? timestamp = int.tryParse(date);

    if (timestamp != null) {
      expirationDates.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
    }
  }
}

}
