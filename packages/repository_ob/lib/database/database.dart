import 'package:objectbox/objectbox.dart';
import 'package:repository/database/database.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';
import 'package:repository_ob/objectbox.g.dart';

mixin ObjectBoxDatabase<T extends Model, O extends ObjectBoxModel> on Database<T> {
  late final Box<O> box;

  @override
  List<T> all() {
    return box.getAll().map(toModel).toList();
  }

  void constructDb(Store store, Preferences preferences) {
    box = store.box<O>();
  }

  @override
  void delete(T item) {
    final query = box.query(_buildIdCondition(item.id)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove((result as dynamic).objectBoxId as int);
    }
  }

  @override
  void deleteAll() {
    box.removeAll();
  }

  @override
  void deleteById(String id) {
    final query = box.query(_buildIdCondition(id)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove((result as dynamic).objectBoxId as int);
    }
  }

  O fromModel(T model);

  @override
  T? get(String id) {
    final query = box.query(_buildIdCondition(id)).build();
    var result = query.findFirst();
    query.close();

    return result != null ? toModel(result) : null;
  }

  @override
  List<T> getAll(List<String> ids) {
    final query = box.query(_buildIdsCondition(ids)).build();
    final results = query.find();
    query.close();

    return results.map(toModel).toList();
  }

  @override
  List<T> getChanges(DateTime since) {
    final query = box.query(_buildSinceCondition(since)).build();
    final results = query.find();
    query.close();

    return results.map(toModel).toList();
  }

  @override
  Map<String, T> map() {
    Map<String, T> map = {};
    final allItems = all();

    for (final record in allItems) {
      map[record.id] = record;
    }

    return map;
  }

  @override
  void put(T item) {
    box.put(fromModel(item));
  }

  T toModel(O objectBoxEntity);

  Condition<O> _buildIdCondition(String id);
  Condition<O> _buildIdsCondition(List<String> ids);
  Condition<O> _buildSinceCondition(DateTime since);
}
