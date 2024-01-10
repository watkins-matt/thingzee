// ignore_for_file: annotate_overrides

import 'package:repository/database/database.dart';
import 'package:repository/model/expiration_date.dart';

abstract class ExpirationDatabase implements Database<ExpirationDate> {
  List<ExpirationDate> all();
  void delete(ExpirationDate date);
  void deleteAll();
  void deleteById(String id);
  ExpirationDate? get(String upc);
  List<ExpirationDate> getAll(List<String> upcs);
  List<ExpirationDate> getChanges(DateTime since);
  String getKey(ExpirationDate item);
  bool isEqual(ExpirationDate a, ExpirationDate b);
  Map<String, ExpirationDate> map();
  ExpirationDate merge(ExpirationDate existingItem, ExpirationDate newItem);
  void put(ExpirationDate date);
}
