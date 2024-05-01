// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxInventory extends ObjectBoxModel<Inventory> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late double amount;
  late int unitCount;
  List<String> locations = [];
  List<DateTime> expirationDates = [];
  late bool restock;
  late String uid;
  @Unique(onConflict: ConflictStrategy.replace)
  late String upc;
  ObjectBoxInventory();
  ObjectBoxInventory.from(Inventory original) {
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
  Inventory convert() {
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
