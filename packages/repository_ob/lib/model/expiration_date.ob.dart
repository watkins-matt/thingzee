// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/expiration_date.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxExpirationDate extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  late DateTime? created;
  late DateTime? updated;
  late String upc;
  late DateTime? expirationDate;
  ObjectBoxExpirationDate();
  ObjectBoxExpirationDate.from(ExpirationDate original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    expirationDate = original.expirationDate;
  }
  ExpirationDate toExpirationDate() {
    return ExpirationDate(
        created: created,
        updated: updated,
        upc: upc,
        expirationDate: expirationDate);
  }
}
