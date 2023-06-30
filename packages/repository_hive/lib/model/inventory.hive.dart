import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/ml/history.dart';
import 'package:repository/model/inventory.dart';

part 'inventory.hive.g.dart';
@HiveType(typeId: 4)
class HiveInventory extends HiveObject {
  @HiveField(0)
  late double amount;
  @HiveField(1)
  late int unitCount;
  @HiveField(2)
  late DateTime? lastUpdate;
  @HiveField(3)
  late List<DateTime> expirationDates;
  @HiveField(4)
  late List<String> locations;
  @HiveField(5)
  late History history;
  @HiveField(6)
  late bool restock;
  @HiveField(7)
  late String upc;
  @HiveField(8)
  late String iuid;
  @HiveField(9)
  late double units;
  HiveInventory();
  HiveInventory.from(Inventory original) {
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
@HiveType(typeId: 5)
class HiveOptDateTimeSerializer extends HiveObject {
  HiveOptDateTimeSerializer();
  HiveOptDateTimeSerializer.from();
  OptDateTimeSerializer toOptDateTimeSerializer() {
    return OptDateTimeSerializer()
    ;
  }
}
