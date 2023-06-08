import 'dart:convert';
import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:quiver/core.dart';
import 'package:repository/model/history.dart';
import 'package:repository/model/inventory.dart';

@Entity()
class ObjectBoxInventory {
  late double amount;
  late int unitCount;
  late Optional<DateTime> lastUpdate;
  List<DateTime> expirationDates = [];
  List<String> locations = [];
  late History history;
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
      ..units = units;
  }

  String get dbHistory {
    return jsonEncode(history.toJson());
  }

  set dbHistory(String value) {
    Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    history = History.fromJson(json).trim();
  }

  int get dbLastUpdate {
    return lastUpdate.isPresent ? lastUpdate.value.millisecondsSinceEpoch : 0;
  }

  set dbLastUpdate(int value) {
    lastUpdate = value != 0
        ? Optional.of(DateTime.fromMillisecondsSinceEpoch(value))
        : const Optional.absent();
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
