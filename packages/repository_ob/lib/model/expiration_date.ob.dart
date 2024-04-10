// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/expiration_date.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxExpirationDate extends ObjectBoxModel<ExpirationDate> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;
  late String upc;
  @Property(type: PropertyType.date)
  late DateTime? expirationDate;
  ObjectBoxExpirationDate();
  ObjectBoxExpirationDate.from(ExpirationDate original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    expirationDate = original.expirationDate;
  }
  ExpirationDate convert() {
    return ExpirationDate(
        created: created,
        updated: updated,
        upc: upc,
        expirationDate: expirationDate);
  }
}
