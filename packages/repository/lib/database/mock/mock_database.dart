import 'package:repository/database/database.dart';
import 'package:repository/model/abstract/model.dart';

mixin MockDatabase<T extends Model> on Database<T> {
  final Map<String, T> db = {};

  @override
  List<T> all() => db.values.toList();

  @override
  void delete(T item) => db.remove(item.uniqueKey);

  @override
  void deleteAll() => db.clear();

  @override
  void deleteById(String id) => db.remove(id);

  @override
  T? get(String id) => db[id];

  @override
  List<T> getAll(List<String> ids) => ids.map((id) => db[id]).whereType<T>().toList();

  @override
  List<T> getChanges(DateTime since) => all().where((item) => item.updated.isAfter(since)).toList();

  @override
  Map<String, T> map() => Map.from(db);

  @override
  void put(T item) => db[item.uniqueKey] = item;
}
