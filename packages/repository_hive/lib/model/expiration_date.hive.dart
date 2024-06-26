// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/expiration_date.dart';

part 'expiration_date.hive.g.dart';

@HiveType(typeId: 0)
class HiveExpirationDate extends HiveObject {
  @HiveField(0)
  late DateTime created;
  @HiveField(1)
  late DateTime updated;
  @HiveField(2)
  late String upc;
  @HiveField(3)
  late DateTime? expirationDate;
  HiveExpirationDate();
  HiveExpirationDate.from(ExpirationDate original) {
    created = original.created;
    updated = original.updated;
    upc = original.upc;
    expirationDate = original.expirationDate;
  }
  ExpirationDate convert() {
    return ExpirationDate(
        created: created,
        expirationDate: expirationDate,
        upc: upc,
        updated: updated);
  }
}
