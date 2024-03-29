import 'package:repository/model/abstract/model.dart';

abstract class Database<T extends Model> {
  List<T> all();
  void delete(T item);
  void deleteAll();
  void deleteById(String id);
  T? get(String id);
  List<T> getAll(List<String> ids);
  List<T> getChanges(DateTime since);
  Map<String, T> map();
  void put(T item);
}
