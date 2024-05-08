// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxInventory extends ObjectBoxModel<Inventory> {
  @Id()
  int objectBoxId = 0;
  late bool restock;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late double amount;
  late int unitCount;
  List<DateTime> expirationDates = [];
  List<String> locations = [];
  late String uid;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  ObjectBoxInventory();
  ObjectBoxInventory.from(Inventory original) {
    amount = original.amount;
    created = original.created;
    expirationDates = original.expirationDates;
    locations = original.locations;
    restock = original.restock;
    uid = original.uid;
    unitCount = original.unitCount;
    upc = original.upc;
    updated = original.updated;
  }
  Inventory convert() {
    return Inventory(
        amount: amount,
        created: created,
        expirationDates: expirationDates,
        locations: locations,
        restock: restock,
        uid: uid,
        unitCount: unitCount,
        upc: upc,
        updated: updated);
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

  int get dbLastUpdate {
    return updated.millisecondsSinceEpoch;
  }

  set dbLastUpdate(int value) {
    updated = DateTime.fromMillisecondsSinceEpoch(value);
  }
}
