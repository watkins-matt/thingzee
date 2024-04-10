import 'package:objectbox/objectbox.dart';
import 'package:repository/database/database.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';
import 'package:repository_ob/objectbox.g.dart';

mixin ObjectBoxDatabase<T extends Model, O extends ObjectBoxModel> on Database<T> {
  late final Box<O> box;

  @override
  List<T> all() => box.getAll().map(convert).toList();

  Condition<O> buildIdCondition(String id);
  Condition<O> buildIdsCondition(List<String> ids);
  Condition<O> buildSinceCondition(DateTime since);

  void constructDb(Store store) {
    box = store.box<O>();
  }

  T convert(O objectBoxEntity) => objectBoxEntity.convert();

  @override
  void delete(T item) {
    assert(item.isValid);

    final query = box.query(buildIdCondition(item.id)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      box.remove(result.objectBoxId);
    }

    replicateOperation((replica) async {
      replica.delete(item);
    });

    callHooks(item, DatabaseHookType.delete);
  }

  @override
  void deleteAll() {
    box.removeAll();

    replicateOperation((replica) async {
      replica.deleteAll();
    });

    callHooks(null, DatabaseHookType.deleteAll);
  }

  @override
  void deleteById(String id) {
    assert(id.isNotEmpty);

    final query = box.query(buildIdCondition(id)).build();
    final result = query.findFirst();
    query.close();

    if (result != null) {
      callHooks(convert(result), DatabaseHookType.delete);
      box.remove(result.objectBoxId);
    }

    replicateOperation((replica) async {
      replica.deleteById(id);
    });
  }

  O fromModel(T model);

  @override
  T? get(String id) {
    final query = box.query(buildIdCondition(id)).build();
    var result = query.findFirst();
    query.close();

    return result != null ? convert(result) : null;
  }

  @override
  List<T> getAll(List<String> ids) {
    final query = box.query(buildIdsCondition(ids)).build();
    final results = query.find().map(convert).toList();
    query.close();
    return results;
  }

  @override
  List<T> getChanges(DateTime since) {
    final query = box.query(buildSinceCondition(since)).build();
    final results = query.find().map(convert).toList();
    query.close();
    return results;
  }

  @override
  Map<String, T> map() {
    return {for (final item in all()) item.id: item};
  }

  @override
  void put(T item) {
    assert(item.isValid);
    final itemOb = fromModel(item);

    final query = box.query(buildIdCondition(item.id)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && itemOb.objectBoxId != exists.objectBoxId) {
      itemOb.objectBoxId = exists.objectBoxId;
    }

    box.put(itemOb);

    replicateOperation((replica) async {
      replica.put(item);
    });

    callHooks(item, DatabaseHookType.put);
  }
}
