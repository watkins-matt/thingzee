import 'dart:core';

import 'package:hive/hive.dart';
import 'package:repository/model/expiration_date.dart';

part 'expiration_date.hive.g.dart';
@HiveType(typeId: 7)
class HiveExpirationDate extends HiveObject {
  @HiveField(0)
  late String upc;
  @HiveField(1)
  late DateTime? date;
  @HiveField(2)
  late DateTime? created;
  HiveExpirationDate();
  HiveExpirationDate.from(ExpirationDate original) {
    upc = original.upc;
    date = original.date;
    created = original.created;
  }
  ExpirationDate toExpirationDate() {
    return ExpirationDate(
      upc: upc,
      date: date,
      created: created
    );
  }
}
