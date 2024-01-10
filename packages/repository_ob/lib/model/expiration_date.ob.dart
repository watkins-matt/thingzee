import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/expiration_date.dart';

@Entity()
class ObjectBoxExpirationDate {
  late DateTime? created;
  late DateTime? updated;
  late String upc;
  late DateTime? expirationDate;
  @Id()
  int objectBoxId = 0;
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
