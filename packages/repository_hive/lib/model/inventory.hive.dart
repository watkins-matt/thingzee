// ignore_for_file: annotate_overrides

import 'package:hive/hive.dart';
import 'package:repository/model/inventory.dart';

part 'inventory.hive.g.dart';

@HiveType(typeId: 0)
class HiveInventory extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late double amount;
  @HiveField(3)
  late int unitCount;
  @HiveField(4)
  late List<String> locations;
  @HiveField(5)
  late List<DateTime> expirationDates;
  @HiveField(6)
  late bool restock;
  @HiveField(7)
  late String uid;
  @HiveField(8)
  late String upc;
  HiveInventory();
  HiveInventory.from(Inventory original) {
    created = original.created;
    updated = original.updated;
    amount = original.amount;
    unitCount = original.unitCount;
    locations = original.locations;
    expirationDates = original.expirationDates;
    restock = original.restock;
    uid = original.uid;
    upc = original.upc;
  }
  Inventory toInventory() {
    return Inventory(
        created: created,
        updated: updated,
        amount: amount,
        unitCount: unitCount,
        locations: locations,
        expirationDates: expirationDates,
        restock: restock,
        uid: uid,
        upc: upc);
  }
}
