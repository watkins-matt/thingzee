abstract class Database<T> {
  List<T> all();
  void delete(T item);
  void deleteAll();
  void deleteById(String id);
  T? get(String id);
  List<T> getAll(List<String> ids);
  List<T> getChanges(DateTime since);
  String getKey(T item);
  Map<String, T> map();
  void put(T item);
}
