import 'dart:core';

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/expiration_date.dart';

@Entity()
class ObjectBoxExpirationDate {
  late String upc;
  late DateTime? date;
  late DateTime? created;
  @Id()
  int objectBoxId = 0;
  ObjectBoxExpirationDate();
  ObjectBoxExpirationDate.from(ExpirationDate original) {
    upc = original.upc;
    date = original.date;
    created = original.created;
  }
  ExpirationDate toExpirationDate() {
    return ExpirationDate(
        upc: upc,
        date: date,
        created: created);
  }
}
