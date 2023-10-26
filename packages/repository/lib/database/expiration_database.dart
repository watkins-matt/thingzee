import 'package:repository/model/expiration_date.dart';

abstract class ExpirationDatabase {
  List<ExpirationDate> all();
  void delete(String upc);
  void deleteAll();
  DateTime? get(String upc);
  List<DateTime> getAll(List<String> upcs);
  List<ExpirationDate> getChanges(DateTime since);
  Map<String, ExpirationDate> map();
  void put(ExpirationDate date);
}
