import 'package:repository/model/abstract/model.dart';

abstract class Database<T extends Model> {
  List<T> all();
  void delete(T item);
  void deleteAll();
  void deleteById(String id);
  T? get(String id);
  List<T> getAll(List<String> ids);
  List<T> getChanges(DateTime since);
  String getKey(T item);
  bool isEqual(T a, T b);
  Map<String, T> map();
  T merge(T existingItem, T newItem);
  void put(T item);
}
