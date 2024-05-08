// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/expiration_date.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxExpirationDate extends ObjectBoxModel<ExpirationDate> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  @Property(type: PropertyType.date)
  late DateTime? expirationDate;
  late String upc;
  ObjectBoxExpirationDate();
  ObjectBoxExpirationDate.from(ExpirationDate original) {
    created = original.created;
    expirationDate = original.expirationDate;
    upc = original.upc;
    updated = original.updated;
  }
  ExpirationDate convert() {
    return ExpirationDate(
        created: created,
        expirationDate: expirationDate,
        upc: upc,
        updated: updated);
  }
}
